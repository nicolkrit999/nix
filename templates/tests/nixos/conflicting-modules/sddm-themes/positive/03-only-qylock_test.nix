{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./03-only-qylock;
in
nix-tests.runTests {
  "P03: only sddm-qylock enabled" = helpers: {
    "no assertion reports mutual exclusion" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "sddm theme is pixel-hollowknight" =
      helpers.isTrue (config.services.displayManager.sddm.theme == "pixel-hollowknight");
  };
}
