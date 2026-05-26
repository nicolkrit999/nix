# Evaluation helper for the sddm display-manager mutual-exclusivity tests.
# Loads just the two sddm modules + stylix (needed because sddm-pixie's let
# block touches config.lib.stylix.colors unconditionally).
let
  flake = builtins.getFlake "path:/home/krit/nix";
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  nixosPaths = [
    /home/krit/nix/templates/tests/nixos/conflicting-modules/sddm-astronaut_sddm-pixie/shared/nixos-extra

    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/nixos/config/constants-nixos.nix

    /home/krit/nix/modules/nixos/services/sddm/sddm-astronaut.nix
    /home/krit/nix/modules/nixos/services/sddm/sddm-pixie.nix
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
