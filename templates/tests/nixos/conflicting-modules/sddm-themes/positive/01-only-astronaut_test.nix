{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-only-astronaut;
in
nix-tests.runTests {
  "P01: only sddm-astronaut enabled" = helpers: {
    "no assertion reports mutual exclusion" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "sddm theme is sddm-astronaut-theme" =
      helpers.isTrue (config.services.displayManager.sddm.theme == "sddm-astronaut-theme");
  };
}
