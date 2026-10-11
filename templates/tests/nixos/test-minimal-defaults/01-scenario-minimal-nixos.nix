# Minimal NixOS defaults scenario.
# Evaluates a host that only sets constants.user = "krit" — everything else
# uses module defaults. Exposes:
#   - build-coexistence: home.activationPackage (for --dry-run)
#   - check-*: "ok" or "FAIL: ..." strings (for nix eval --raw)
#
# Only the auto-enabled modules being checked are in the path list.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;

  nixosPaths = [
    (src + "/templates/tests/nixos/test-minimal-defaults/shared/nixos-extra-x86_64")
    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/services/hypr/hypridle.nix")
  ];

  hosts = denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with denix.lib.extensions; [
      args
      (base.withConfig {
        args.enable = true;
        rices.enable = false;
      })
    ];
    specialArgs = {
      inputs = flake.inputs;
      moduleSystem = "nixos";
    };
    paths = [
      (src + "/templates/tests/nixos/test-minimal-defaults/shared/host-minimal-nixos.nix")
      (src + "/templates/tests/nixos/test-minimal-defaults/shared/host-override-nixos.nix")
      (src + "/templates/tests/nixos/test-minimal-defaults/shared/host-nowm-nixos.nix")
    ] ++ nixosPaths;
    exclude = [ ];
  };

  min = hosts.minimal-nixos.config;
  over = hosts.override-nixos.config;
  nowm = hosts.nowm-nixos.config;

  hmOf = cfg: user: cfg.home-manager.users.${user};
  timeouts = cfg: user:
    map (l: l.timeout) (hmOf cfg user).services.hypridle.settings.listener;
  cfgTimeouts = cfg:
    let h = cfg.myconfig.services.hypridle; in [ h.dimTimeout h.lockTimeout h.screenOffTimeout ];
  ordered = ts: let a = builtins.elemAt ts 0; b = builtins.elemAt ts 1; c = builtins.elemAt ts 2; in a < b && b < c;

  check = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
in
{
  build-coexistence = (hmOf min "krit").home.activationPackage;

  check-emergency-access-off =
    check "constants.emergencyAccess" min.myconfig.constants.emergencyAccess false;

  check-screenshots-abs-default =
    check "screenshotsAbs (user krit)" min.myconfig.constants.screenshotsAbs "/home/krit/Pictures/Screenshots";
  check-screenshots-abs-follows-user =
    check "screenshotsAbs (user alice)" over.myconfig.constants.screenshotsAbs "/home/alice/Pictures/Screenshots";

  check-primary-wallpaper-is-fallback =
    check "primaryWallpaper.wallpaperURL"
      min.myconfig.constants.primaryWallpaper.wallpaperURL
      min.myconfig.constants.fallbackWallpaperURL;

  check-idle-timeouts-ordered-default =
    check "hypridle default timeouts ordered dim<lock<off" (ordered (cfgTimeouts min)) true;
  check-idle-timeouts-reach-listeners-default =
    check "hypridle listeners (default)" (timeouts min "krit") (cfgTimeouts min);
  check-idle-timeouts-reach-listeners-override =
    check "hypridle listeners (override)" (timeouts over "krit") [ 100 200 250 ];

  check-hyprland-wrapper-no-caps =
    check "security.wrappers.Hyprland.capabilities" min.security.wrappers.Hyprland.capabilities "";
  check-hyprland-disabled-no-nixos-hyprland =
    check "programs.hyprland.enable (hyprland off)" nowm.programs.hyprland.enable false;
  check-no-wm-no-idle-actions =
    check "hm services.hypridle.enable (no WM)" (hmOf nowm "krit").services.hypridle.enable false;
}
