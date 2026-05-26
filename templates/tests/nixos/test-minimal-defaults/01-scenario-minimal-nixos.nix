# Minimal NixOS defaults scenario.
# Evaluates a host that only sets constants.user = "krit" — everything else
# uses module defaults. Exposes:
#   - build-coexistence: home.activationPackage (for --dry-run)
#   - check-*: "ok" or "FAIL: ..." strings (for nix eval --raw)
#
# Only the auto-enabled modules being checked are in the path list.
let
  flake = builtins.getFlake "path:/home/krit/nix";
  denix = flake.inputs.denix;

  nixosPaths = [
    # x86_64 platform override + HM base + stylix stub
    /home/krit/nix/templates/tests/nixos/test-minimal-defaults/shared/nixos-extra-x86_64

    # Constants schema and HM wiring
    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/nixos/config/constants-nixos.nix
    /home/krit/nix/modules/common/themes/catppuccin.nix

    # WM enable options — include all three so cross-WM guards evaluate cleanly
    /home/krit/nix/modules/nixos/toplevel/hyprland.nix
    /home/krit/nix/modules/nixos/toplevel/niri.nix
    /home/krit/nix/modules/nixos/toplevel/mango.nix

    # Hyprland DE modules (needed for HM wayland.windowManager.hyprland.* options)
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix
    /home/krit/nix/modules/nixos/programs/de-wm/hyprland/hyprland-hyprpaper.nix

    # Hyprland ecosystem: all auto-enabled (boolOption true) once hyprland is on
    /home/krit/nix/modules/nixos/services/hypr/hypridle.nix
    /home/krit/nix/modules/nixos/services/hypr/hyprlock.nix
    /home/krit/nix/modules/nixos/services/swaync.nix
    /home/krit/nix/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix

    # Shell modules — required so hyprland-main's *Integration toggles evaluate
    /home/krit/nix/modules/common/programs/shells/bash.nix
    /home/krit/nix/modules/common/programs/shells/fish.nix
    /home/krit/nix/modules/common/programs/shells/zsh.nix
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
      /home/krit/nix/templates/tests/nixos/test-minimal-defaults/shared/host-minimal-nixos.nix
    ] ++ nixosPaths;
    exclude = [ ];
  }).minimal-nixos.config;

  hm = config.home-manager.users.krit;
  c = config.myconfig.constants;

  checkBool = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${if expected then "true" else "false"}, got ${if actual then "true" else "false"}";

  checkStr = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected '${expected}', got '${actual}'";
in
{
  # ── Build coexistence ────────────────────────────────────────────────────────
  build-coexistence = hm.home.activationPackage;

  # ── Constant defaults (from constants-nixos.nix) ─────────────────────────────
  check-constant-shell = checkStr "constants.shell" c.shell "bash";
  check-constant-terminal = checkStr "constants.terminal.name" c.terminal.name "alacritty";
  check-constant-browser = checkStr "constants.browser" c.browser "chromium";
  check-constant-editor = checkStr "constants.editor" c.editor "nano";
  check-constant-filemanager = checkStr "constants.fileManager" c.fileManager "dolphin";
  check-constant-catppuccin = checkBool "constants.theme.catppuccin" c.theme.catppuccin false;

  # ── Auto-enabled module states ───────────────────────────────────────────────
  check-hyprland-enabled =
    checkBool "programs.hyprland.enable" config.myconfig.programs.hyprland.enable true;
  check-stylix-enabled =
    checkBool "myconfig.stylix.enable" config.myconfig.stylix.enable true;
  check-swaync-enabled =
    checkBool "services.swaync.enable" config.myconfig.services.swaync.enable true;
  check-hyprlock-enabled =
    checkBool "services.hyprlock.enable" config.myconfig.services.hyprlock.enable true;
  check-hypridle-enabled =
    checkBool "services.hypridle.enable" config.myconfig.services.hypridle.enable true;
  check-waybar-hyprland-enabled =
    checkBool "programs.waybar-hyprland.enable" config.myconfig.programs.waybar-hyprland.enable true;
}
