# Evaluation helper for the power-management mutual-exclusivity tests.
# Mirrors the test-custom-shells pattern but trimmed to just the two power
# modules — no WMs, shells, waybars or themes are loaded.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  nixosPaths = [
    (src + "/templates/tests/nixos/conflicting-modules/auto-cpu-freq_tlp/shared/nixos-extra")

    (src + "/modules/common/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")

    (src + "/modules/nixos/services/power/auto-cpufreq.nix")
    (src + "/modules/nixos/services/power/thermald.nix")
    (src + "/modules/nixos/services/power/tlp.nix")
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
