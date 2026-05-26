# Minimal Darwin defaults scenario.
# Evaluates a host with only basic identity constants set — everything else
# uses module defaults. Exposes check-* attributes as "ok" or "FAIL: ...".
#
# Eval-only (no build check — Darwin cross-builds from Linux are heavy).
#
# Usage:
#   nix eval --raw --impure --file this.nix check-<name>
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  denix = flake.inputs.denix;

  darwinPaths = [
    # Stylix stub with dummy image (replaces modules/darwin/toplevel/stylix-darwin.nix)
    /home/krit/nix/templates/tests/darwin/test-minimal-defaults/shared/darwin-extra

    # Constants schema and HM wiring
    /home/krit/nix/modules/darwin/config/constants-darwin.nix
    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/common/themes/catppuccin.nix

    # Darwin always-on infrastructure
    /home/krit/nix/modules/darwin/toplevel/common-configuration-darwin.nix
    /home/krit/nix/modules/darwin/toplevel/home-darwin.nix
    /home/krit/nix/modules/darwin/toplevel/user-darwin.nix
    /home/krit/nix/modules/darwin/toplevel/nix-darwin.nix

    # Auto-enabled module under test
    /home/krit/nix/modules/darwin/toplevel/home-packages-darwin.nix
  ];

  config = (denix.lib.configurations {
    moduleSystem = "darwin";
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
      moduleSystem = "darwin";
    };
    paths = [
      /home/krit/nix/templates/tests/darwin/test-minimal-defaults/shared/host-minimal-darwin.nix
    ] ++ darwinPaths;
    exclude = [ ];
  }).minimal-darwin.config;

  c = config.myconfig.constants;

  checkBool = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected ${if expected then "true" else "false"}, got ${if actual then "true" else "false"}";

  checkStr = name: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${name}: expected '${expected}', got '${actual}'";
in
{
  # ── Constant defaults (from constants-darwin.nix) ────────────────────────────
  check-constant-shell = checkStr "constants.shell" c.shell "bash";
  check-constant-terminal = checkStr "constants.terminal.name" c.terminal.name "alacritty";
  check-constant-browser = checkStr "constants.browser" c.browser "firefox";
  check-constant-editor = checkStr "constants.editor" c.editor "nano";
  check-constant-filemanager = checkStr "constants.fileManager" c.fileManager "nnn";
  check-constant-catppuccin = checkBool "constants.theme.catppuccin" c.theme.catppuccin false;

  # ── Auto-enabled module states ───────────────────────────────────────────────
  check-stylix-enabled =
    checkBool "myconfig.stylix.enable" config.myconfig.stylix.enable true;
  check-home-packages-enabled =
    checkBool "home-packages.enable" config.myconfig.home-packages.enable true;
}
