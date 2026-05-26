# Specialization contract scenario.
# Evaluates a fake host with only the modules that specializations touch, then
# reads each specialization's config to verify lib.mkForce overrides landed.
#
# All checks return "ok" or "FAIL: <detail>" for use with nix eval --raw.
#
# Usage:
#   nix eval --raw --impure --file this.nix --attr check-<name>
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  nixosPaths = [
    # x86_64 platform override + home-manager base + stylix stub
    /home/krit/nix/templates/tests/nixos/test-spec-contract/shared/nixos-extra-x86_64

    # Core infrastructure
    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/nixos/config/constants-nixos.nix
    /home/krit/nix/modules/nixos/toplevel/nix-nixos.nix
    /home/krit/nix/modules/common/themes/catppuccin.nix
    /home/krit/nix/modules/nixos/toplevel/common-configuration-nixos.nix

    # WM enable options — specs reference myconfig.programs.*.enable on all of these
    /home/krit/nix/modules/nixos/toplevel/hyprland.nix
    /home/krit/nix/modules/nixos/toplevel/niri.nix
    /home/krit/nix/modules/nixos/toplevel/mango.nix
    /home/krit/nix/modules/nixos/toplevel/gnome.nix
    /home/krit/nix/modules/nixos/toplevel/kde.nix
    /home/krit/nix/modules/nixos/toplevel/cosmic.nix

    # Hyprland DE modules (needed for monitors/execOnce/windowRules options)
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-hyprpaper.nix

    # Niri DE modules (school/home specs reference niri.execOnce, niri.outputs)
    /home/krit/nix/modules/nixos/programs/de-wm/niri/niri-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/niri/niri-binds.nix

    # Mango DE modules (school/home specs reference mango.execOnce, mango.monitors)
    /home/krit/nix/modules/nixos/programs/de-wm/mango/mango-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/mango/mango-binds.nix

    # Gnome DE modules (secure-travel forces gnome.enable = true)
    /home/krit/nix/modules/nixos/programs/de-wm/gnome/gnome-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/gnome/gnome-binds.nix

    # KDE DE modules (entertainment forces kde.enable = true; plasma-manager HM options)
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-desktop.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-files.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-inputs.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-krunner.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-kscreenlocker.nix
    /home/krit/nix/modules/nixos/programs/de-wm/kde/kde-panels.nix

    # Custom shells (enabled in host so guest/safe-mode/secure-travel overrides are real)
    /home/krit/nix/modules/nixos/programs/shells/caelestia-main.nix
    /home/krit/nix/modules/nixos/programs/shells/noctalia-main.nix

    # Programs whose enable options specs override
    /home/krit/nix/modules/common/programs/claude-code.nix
    /home/krit/nix/modules/nixos/programs/claude-desktop.nix
    /home/krit/nix/modules/nixos/programs/nix-alien.nix
    /home/krit/nix/modules/nixos/programs/nix-ld.nix

    # Services whose enable options specs override
    /home/krit/nix/modules/nixos/services/hypr/hypridle.nix
    /home/krit/nix/modules/nixos/services/hypr/hyprlock.nix
    /home/krit/nix/modules/nixos/services/swaync.nix
    /home/krit/nix/modules/common/services/tailscale.nix
    /home/krit/nix/modules/nixos/toplevel/bluetooth.nix

    # Shell modules (used by safe-mode to force bash and by school initExtra)
    /home/krit/nix/modules/common/programs/shells/bash.nix
    /home/krit/nix/modules/common/programs/shells/fish.nix
    /home/krit/nix/modules/common/programs/shells/zsh.nix

    # Global specializations
    /home/krit/nix/modules/nixos/specializations/deep-focus.nix
    /home/krit/nix/modules/nixos/specializations/guest.nix
    /home/krit/nix/modules/nixos/specializations/safe-mode.nix
    /home/krit/nix/modules/nixos/specializations/secure-travel.nix

    # Minimal user infrastructure
    /home/krit/nix/users/krit/nixos/common/home/home-base.nix
    /home/krit/nix/users/krit/nixos/common/system/default-user.nix
    /home/krit/nix/users/krit/nixos/common/system/virtualisation.nix

    # krit specializations
    /home/krit/nix/users/krit/nixos/specializations/entertainment.nix
    /home/krit/nix/users/krit/nixos/specializations/home.nix
    /home/krit/nix/users/krit/nixos/specializations/school.nix
  ];

  config = (denix.lib.configurations {
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
      /home/krit/nix/templates/tests/nixos/test-spec-contract/shared/host-spec-contract.nix
    ] ++ nixosPaths;
    exclude = [ ];
  }).spec-contract.config;

  # spec name → full NixOS config with that specialization applied
  spec = name: config.specialisation.${name}.configuration;
  # specHm name → home-manager krit config within that specialization
  specHm = name: (spec name).home-manager.users.krit;

  checkBool = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${if expected then "true" else "false"}, got ${if actual then "true" else "false"}";

  checkStr = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected '${expected}', got '${actual}'";

  checkContains = name: str: substr:
    if lib.strings.hasInfix substr str then "ok"
    else "FAIL: ${name}: expected to contain '${substr}'";

  checkNonEmpty = name: lst:
    if builtins.length lst > 0 then "ok"
    else "FAIL: ${name}: expected non-empty list, got []";

  checkPkgInList = name: pkglist: pname:
    if builtins.any (p: (p.pname or p.name or "") == pname) pkglist then "ok"
    else "FAIL: ${name}: package '${pname}' not found in home.packages";
in
{
  # ── guest ────────────────────────────────────────────────────────────────────
  check-guest-hyprland-disabled =
    checkBool "guest.hyprland.enable" (spec "guest").myconfig.programs.hyprland.enable false;
  check-guest-stylix-disabled =
    checkBool "guest.myconfig.stylix.enable" (spec "guest").myconfig.stylix.enable false;
  check-guest-bluetooth-disabled =
    checkBool "guest.bluetooth.enable" (spec "guest").myconfig.bluetooth.enable false;
  check-guest-hyprlock-disabled =
    checkBool "guest.services.hyprlock.enable" (spec "guest").myconfig.services.hyprlock.enable false;
  check-guest-swaync-disabled =
    checkBool "guest.services.swaync.enable" (spec "guest").myconfig.services.swaync.enable false;
  # The .desktop text holds the derivation Exec path, not the zenity call directly;
  # verifying "guest-welcome" confirms the autostart entry points to the right wrapper.
  check-guest-welcome-desktop =
    checkContains "guest autostart .desktop"
      (spec "guest").environment.etc."xdg/autostart/guest-welcome.desktop".text
      "guest-welcome";

  # ── safe-mode ────────────────────────────────────────────────────────────────
  check-safemode-stylix-disabled =
    checkBool "safemode.myconfig.stylix.enable" (spec "safemode").myconfig.stylix.enable false;
  check-safemode-shell-bash =
    checkStr "safemode.constants.shell" (spec "safemode").myconfig.constants.shell "bash";
  check-safemode-terminal-xterm =
    checkStr "safemode.constants.terminal.name" (spec "safemode").myconfig.constants.terminal.name "xterm";
  check-safemode-hyprland-disabled =
    checkBool "safemode.hyprland.enable" (spec "safemode").myconfig.programs.hyprland.enable false;
  check-safemode-icewm-enabled =
    checkBool "safemode.icewm.enable" (spec "safemode").services.xserver.windowManager.icewm.enable true;
  check-safemode-startx-enabled =
    checkBool "safemode.startx.enable" (spec "safemode").services.xserver.displayManager.startx.enable true;
  check-safemode-xinitrc-has-icewm =
    checkContains "safemode .xinitrc"
      (specHm "safemode").home.file.".xinitrc".text
      "icewm-session";
  check-safemode-alias-start-icewm =
    checkStr "safemode.shellAliases.start-icewm"
      ((specHm "safemode").home.shellAliases."start-icewm" or "MISSING")
      "startx";

  # ── deep-focus ───────────────────────────────────────────────────────────────
  check-deepfocus-swaync-enabled =
    checkBool "deep-focus.services.swaync.enable" (spec "deep-focus").myconfig.services.swaync.enable true;

  # ── secure-travel ─────────────────────────────────────────────────────────────
  check-securetravel-bluetooth-disabled =
    checkBool "secure-travel.bluetooth.enable" (spec "secure-travel").myconfig.bluetooth.enable false;
  check-securetravel-hyprland-disabled =
    checkBool "secure-travel.hyprland.enable" (spec "secure-travel").myconfig.programs.hyprland.enable false;
  check-securetravel-tailscale-disabled =
    checkBool "secure-travel.tailscale.enable" (spec "secure-travel").myconfig.services.tailscale.enable false;
  check-securetravel-nix-ld-disabled =
    checkBool "secure-travel.nix-ld.enable" (spec "secure-travel").myconfig.programs.nix-ld.enable false;
  check-securetravel-gnome-enabled =
    checkBool "secure-travel.gnome.enable" (spec "secure-travel").myconfig.programs.gnome.enable true;
  check-securetravel-killswitch-exists =
    checkNonEmpty "secure-travel NM dispatcherScripts"
      (spec "secure-travel").networking.networkmanager.dispatcherScripts;

  # ── entertainment ─────────────────────────────────────────────────────────────
  check-entertainment-kde-enabled =
    checkBool "entertainment.kde.enable" (spec "entertainment").myconfig.programs.kde.enable true;
  check-entertainment-hyprland-disabled =
    checkBool "entertainment.hyprland.enable" (spec "entertainment").myconfig.programs.hyprland.enable false;

  # ── school ────────────────────────────────────────────────────────────────────
  check-school-browser-constant =
    checkStr "school.constants.browser" (spec "school").myconfig.constants.browser "brave-school";
  check-school-editor-constant =
    checkStr "school.constants.editor" (spec "school").myconfig.constants.editor "vscode-school";
  check-school-setup-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-setup";
  check-school-check-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-check";
  check-school-clear-script =
    checkPkgInList "school home.packages" (specHm "school").home.packages "school-distrobox-clear";

  # ── home ──────────────────────────────────────────────────────────────────────
  check-home-monitors-nonempty =
    checkNonEmpty "home spec hyprland.monitors" (spec "home").myconfig.programs.hyprland.monitors;
}
