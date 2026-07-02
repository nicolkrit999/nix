# Evaluation helper for the sddm display-manager mutual-exclusivity tests.
# Loads just the two sddm modules + stylix (needed because sddm-pixie's let
# block touches config.lib.stylix.colors unconditionally).
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  nixosPaths = [
    (src + "/templates/tests/nixos/conflicting-modules/sddm-astronaut_sddm-pixie/shared/nixos-extra")

    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")

    (src + "/modules/nixos/services/sddm/sddm-astronaut.nix")
    (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
  ];

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
      exclude = [ ];
    };

  getConfig = scenarioDir:
    let
      configs = evalScenario scenarioDir;
      names = builtins.attrNames configs;
    in
    configs.${builtins.head names}.config;

  getAssertions = config: config.assertions or [ ];

  hasFailingAssertion = msgSubstr: config:
    let
      matches = builtins.filter
        (a: !(a.assertion) && lib.hasInfix msgSubstr a.message)
        (getAssertions config);
    in
    builtins.length matches > 0;

in
{
  inherit evalScenario getConfig getAssertions hasFailingAssertion;
  inherit lib flake;
}
