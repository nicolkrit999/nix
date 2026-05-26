# P02 — Only sddm-pixie enabled. Expected: assertion does not fire, sddm theme = pixie.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./02-only-pixie;
in
nix-tests.runTests {
  "P02: only sddm-pixie enabled" = helpers: {
    "mutual-exclusivity assertion does NOT fire" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "sddm theme is pixie" =
      helpers.isTrue (config.services.displayManager.sddm.theme == "pixie");
  };
}
