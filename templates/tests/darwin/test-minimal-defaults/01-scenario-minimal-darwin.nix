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
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;

  darwinPaths = [
    # Constants schema and HM wiring
    (src + "/modules/darwin/config/constants-darwin.nix")
    (src + "/modules/common/config/constants.nix")
    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/common/themes/catppuccin.nix")

    # Darwin always-on infrastructure
    (src + "/modules/darwin/toplevel/common-configuration-darwin.nix")
    (src + "/modules/darwin/toplevel/home-darwin.nix")
    (src + "/modules/darwin/toplevel/user-darwin.nix")
    (src + "/modules/darwin/toplevel/nix-darwin.nix")

    # Module under test (body is forced via environment.systemPackages)
    (src + "/modules/darwin/toplevel/home-packages-darwin.nix")
  ];

  configs = (denix.lib.configurations {
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
      (src + "/templates/tests/darwin/test-minimal-defaults/shared/host-minimal-darwin.nix")
      (src + "/templates/tests/darwin/test-minimal-defaults/shared/host-nobrowser-darwin.nix")
    ] ++ darwinPaths;
    exclude = [ ];
  });

  config = configs.minimal-darwin.config;
  c = config.myconfig.constants;

  hasPkg = cfg: n:
    builtins.elem n (map (p: p.pname or (builtins.parseDrvName p.name).name) cfg.environment.systemPackages);

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

  # ── Module body forced: browser fallback lands, and "" opts out (control) ────
  check-home-packages-installs-browser =
    checkBool "systemPackages has firefox (default host)" (hasPkg config "firefox") true;
  check-home-packages-browser-optout =
    checkBool "systemPackages has firefox (browser = \"\" host)"
      (hasPkg configs.nobrowser-darwin.config "firefox")
      false;
  check-constant-override-lands =
    checkStr "nobrowser host constants.browser" configs.nobrowser-darwin.config.myconfig.constants.browser "";
}
