# Slim fake host for one portal case (PORTAL_CASE, JSON: { desktops = [...]; hmPortal = bool; }).
# Loads only the repo's xdg-portal module, the desktop toggles and the HM integration; no
# user programs, no theming, no specialisations.
#
#   --attr info        eval-only data (config, portal package names, profile entries, sessions)
#   --attr realise     stand-ins + uncached trivial entries named in BUILD (JSON outPath list)
#   --attr xdp / dbus  the binaries the simulation runs
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  here = src + "/templates/tests/nixos/test-portal-routing";

  configs = flake.inputs.denix.lib.configurations {
    moduleSystem = "nixos";
    homeManagerUser = "krit";
    extensions = with flake.inputs.denix.lib.extensions; [
      args
      (base.withConfig { args.enable = true; rices.enable = false; })
    ];
    specialArgs = { inherit (flake) inputs; moduleSystem = "nixos"; };
    paths = [
      (here + "/fake-host")
      (src + "/modules/nixos/toplevel/home-manager.nix")
      (src + "/modules/nixos/config/constants-nixos.nix")
      (src + "/modules/common/config/constants.nix")
      (src + "/modules/nixos/toplevel/xdg-portal.nix")
      (src + "/modules/nixos/toplevel/hyprland.nix")
      (src + "/modules/nixos/toplevel/niri.nix")
      (src + "/modules/nixos/toplevel/mango.nix")
      (src + "/modules/nixos/toplevel/kde.nix")
      (src + "/modules/nixos/toplevel/gnome.nix")
      (src + "/modules/nixos/toplevel/cosmic.nix")
    ];
  };
  c = configs.portal-fake.config;
  pkgs = configs.portal-fake.pkgs;
  hm = c.home-manager.users.krit;
  common = import ./portal-common.nix { inherit lib pkgs flake; };

  hmOn = hm.xdg.portal.enable or false;
  sysEntries = c.system.path.paths;
  hmEntries = if hmOn then hm.home.path.paths else [ ];

  build = let b = builtins.getEnv "BUILD"; in if b == "" then [ ] else builtins.fromJSON b;
  allEntries = sysEntries ++ hmEntries ++ c.services.displayManager.sessionPackages;
in
{
  info = {
    portalConfig = c.xdg.portal.config;
    hmPortalConfig = hm.xdg.portal.config;
    hmPortal = hmOn;
    sysPortalNames = common.names (c.xdg.portal.extraPortals ++ c.xdg.portal.configPackages);
    hmPortalNames = if hmOn then common.names (hm.xdg.portal.extraPortals ++ hm.xdg.portal.configPackages) else [ ];
    sessionNames = lib.sort lib.lessThan (lib.unique (lib.concatMap (p: p.providedSessions or [ ]) c.services.displayManager.sessionPackages));
    xdpPath = pkgs.xdg-desktop-portal.outPath;
    sessions = map common.entryDrv c.services.displayManager.sessionPackages;
    sys = map common.entryDrv sysEntries;
    hm = map common.entryDrv hmEntries;
  };
  # Everything this case realises besides xdp and dbus: stand-ins plus the uncached entries
  # the helper classified as trivial (BUILD: JSON outPath list).
  realise = lib.unique (lib.filter (x: x != null) (map common.standIn allEntries)
    ++ lib.filter (p: lib.elem p.outPath build) allEntries);
  xdp = pkgs.xdg-desktop-portal;
  inherit (pkgs) dbus;
}
