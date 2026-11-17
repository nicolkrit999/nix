# Evaluation helper for the sddm display-manager mutual-exclusivity tests.
# Loads the three sddm theme modules, the shared exclusivity assertion and stylix
# (needed because sddm-pixie's let block touches config.lib.stylix.colors unconditionally).
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  lib = flake.inputs.nixpkgs.lib;
  denix = flake.inputs.denix;

  nixosPaths = [
    (src + "/templates/tests/nixos/conflicting-modules/sddm-themes/shared/nixos-extra")

    (src + "/modules/nixos/toplevel/home-manager.nix")
    (src + "/modules/nixos/config/constants-nixos.nix")
    (src + "/modules/common/config/constants.nix")

    (src + "/modules/nixos/services/sddm/sddm-astronaut.nix")
    (src + "/modules/nixos/services/sddm/sddm-pixie.nix")
    (src + "/modules/nixos/services/sddm/sddm-qylock.nix")
    (src + "/modules/nixos/services/sddm/sddm-exclusive.nix")
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
        inherit (flake) inputs;
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
        (a: !a.assertion && lib.hasInfix msgSubstr a.message)
        (getAssertions config);
    in
    builtins.length matches > 0;

  allAssertionsPass = config:
    builtins.all (a: a.assertion) (getAssertions config);

  failingCount = msgSubstr: config:
    builtins.length (builtins.filter
      (a: !a.assertion && lib.hasInfix msgSubstr a.message)
      (getAssertions config));

in
{
  inherit evalScenario getConfig getAssertions allAssertionsPass hasFailingAssertion failingCount;
  inherit lib flake;
}
