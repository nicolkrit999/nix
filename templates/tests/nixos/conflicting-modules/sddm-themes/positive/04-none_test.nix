{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./04-none;
in
nix-tests.runTests {
  "P04: no SDDM theme module enabled" = helpers: {
    "no assertion reports mutual exclusion" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "sddm is not enabled by any theme module" =
      helpers.isFalse (config.services.displayManager.sddm.enable or false);
  };
}
