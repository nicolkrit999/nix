{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./02-only-pixie;
in
nix-tests.runTests {
  "P02: only sddm-pixie enabled" = helpers: {
    "no assertion reports mutual exclusion" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "sddm theme is pixie" =
      helpers.isTrue (config.services.displayManager.sddm.theme == "pixie");
  };
}
