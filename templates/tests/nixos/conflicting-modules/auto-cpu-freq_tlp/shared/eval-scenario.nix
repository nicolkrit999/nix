# Evaluation helper for the power-management mutual-exclusivity tests.
# Mirrors the test-custom-shells pattern but trimmed to just the two power
# modules — no WMs, shells, waybars or themes are loaded.
let
  flake = builtins.getFlake "path:/home/krit/nix";
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  nixosPaths = [
    /home/krit/nix/templates/tests/nixos/conflicting-modules/auto-cpu-freq_tlp/shared/nixos-extra

    /home/krit/nix/modules/common/toplevel/home-manager.nix
    /home/krit/nix/modules/nixos/config/constants-nixos.nix

    /home/krit/nix/modules/nixos/services/power/auto-cpufreq.nix
    /home/krit/nix/modules/nixos/services/power/tlp.nix
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

  # System-level assertions only — the power modules don't touch home-manager.
  getAssertions = config: config.assertions or [ ];

  allAssertionsPass = config:
    builtins.all (a: a.assertion) (getAssertions config);

  hasFailingAssertion = msgSubstr: config:
    let
      matches = builtins.filter
        (a: !(a.assertion) && lib.hasInfix msgSubstr a.message)
        (getAssertions config);
    in
    builtins.length matches > 0;

in
{
  inherit evalScenario getConfig getAssertions allAssertionsPass hasFailingAssertion;
  inherit lib flake;
}
