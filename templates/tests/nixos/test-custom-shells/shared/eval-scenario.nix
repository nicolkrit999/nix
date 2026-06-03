# Core evaluation helper for the activation-contract test suite.
#
# Provides:
#   evalScenario  scenarioDir            -> nixosConfigurations attrset
#   getConfig     scenarioDir            -> resolved NixOS config
#   getHm         config                 -> home-manager sub-config for "krit"
#   getAllAssertions  config             -> system + HM assertions combined
#   allAssertionsPass  config            -> bool: true iff no assertion fails
#   hasFailingAssertion  msgSubstr config -> bool: true iff a failing assertion
#                                           contains msgSubstr in its message
#
# Assertions live in two places depending on the block they were declared in:
#   nixos.always/ifEnabled  -> config.assertions
#   home.always/ifEnabled   -> config.home-manager.users.krit.assertions
# getAllAssertions combines both so tests don't need to know which is which.
#
# Uses builtins.getFlake "path:/home/krit/nix" which works without --impure
# because the path: scheme is a proper flake URI.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  # Exact file paths for the modules under test. Including only what the
  # activation-contract tests care about keeps eval fast and avoids pulling
  # in unrelated modules (librewolf, gnome, kde, cosmic, sops, bluetooth…)
  # that would need extra specialArgs or excludes.
  #
  # Every test recognises all WMs, shells, and waybars so that "wrong WM"
  # scenarios don't silently pass because the option is simply absent.
  nixosPaths = [
    # nixos-extra: sets nixpkgs.hostPlatform (required by the NixOS module system)
    (src + "/templates/tests/nixos/test-custom-shells/shared/nixos-extra")

    # home-manager integration (needed so config.home-manager.users.krit.* exists)
    (src + "/modules/common/toplevel/home-manager.nix")

    # Constants schema (declares myconfig.constants.* options)
    (src + "/modules/nixos/config/constants-nixos.nix")

    # Catppuccin: adds catppuccin.* home-manager options (needed by hyprland-main)
    (src + "/modules/common/themes/catppuccin.nix")

    # NOTE: stylix-nixos.nix is intentionally NOT included — it would fetch
    # wallpapers. Instead, nixos-extra/stylix-hm.nix sets stylix directly
    # with only a base16 scheme so that lib.stylix.colors.* is available.

    # WM enable options (singleEnableOption — separate from the main modules)
    (src + "/modules/nixos/toplevel/hyprland.nix")
    (src + "/modules/nixos/toplevel/niri.nix")
    (src + "/modules/nixos/toplevel/mango.nix")

    # Window manager main modules + binds + extras
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-main.nix")
    (src + "/modules/nixos/programs/de-wm/hyprland/hyprland-binds.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-main.nix")
    (src + "/modules/nixos/programs/de-wm/niri/niri-binds.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-main.nix")
    (src + "/modules/nixos/programs/de-wm/mango/mango-binds.nix")

    # Custom shells
    (src + "/modules/nixos/programs/shells/caelestia-main.nix")
    (src + "/modules/nixos/programs/shells/noctalia-main.nix")

    # Waybars (one per WM)
    (src + "/modules/nixos/programs/waybar/hyprland/waybar-hyprland.nix")
    (src + "/modules/nixos/programs/waybar/niri/waybar-niri.nix")
    (src + "/modules/nixos/programs/waybar/mango/waybar-mango.nix")

    # Services that the activation contract controls
    (src + "/modules/nixos/services/swaync.nix")
    (src + "/modules/nixos/services/hypr/hyprlock.nix")
  ];

  # No broad excludes needed — we list exact files above.
  baseExclude = [ ];

  evalScenario = scenarioDir:
    denix.lib.configurations {
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
      paths = [ scenarioDir ] ++ nixosPaths;
      exclude = baseExclude;
    };

  # Get the resolved NixOS config for the single fake host in scenarioDir.
  getConfig = scenarioDir:
    let
      configs = evalScenario scenarioDir;
      names = builtins.attrNames configs;
    in
    configs.${builtins.head names}.config;

  # Render a Hyprland lua-mode bind entry into a searchable string.
  # In 26.05 lua mode each bind is a table `{ _args = [ keyStr luaInline flags? ]; }`
  # rather than a plain "MODS, KEY, dispatch, arg" string, so substring assertions
  # must flatten it first. String args pass through; lua-inline dispatchers
  # contribute their `.expr`; flag attrsets are dropped.
  bindStr = b:
    if builtins.isString b then b
    else
      lib.concatStringsSep " " (map
        (a:
          if builtins.isString a then a
          else if builtins.isAttrs a && (a._type or "") == "lua-inline" then a.expr
          else "")
        (b._args or [ ]));

  # Home-manager sub-config for user krit.
  getHm = config: config.home-manager.users.krit;

  # Combine system-level and home-manager assertions into one list.
  getAllAssertions = config:
    (config.assertions or [ ])
    ++ ((getHm config).assertions or [ ]);

  # Home-manager assertions only — our custom activation-contract assertions
  # all live in home.always / home.ifEnabled blocks. Standard NixOS system
  # assertions (boot loader, fileSystems, user config) are irrelevant here.
  getHmAssertions = config: (getHm config).assertions or [ ];

  # True iff every HOME-MANAGER assertion in the scenario passes.
  # (Standard NixOS system assertions are excluded — they would always fail
  # in a minimal test env that has no boot loader or filesystems configured.)
  allAssertionsPass = config:
    builtins.all (a: a.assertion) (getHmAssertions config);

  # True iff at least one FAILING assertion (from either HM or system level)
  # has a message containing msgSubstr.
  hasFailingAssertion = msgSubstr: config:
    let
      all = getAllAssertions config;
      matches = builtins.filter
        (a: !(a.assertion) && lib.hasInfix msgSubstr a.message)
        all;
    in
    builtins.length matches > 0;

in
{
  inherit evalScenario getConfig getHm getAllAssertions allAssertionsPass hasFailingAssertion bindStr;
  inherit lib flake;
}
