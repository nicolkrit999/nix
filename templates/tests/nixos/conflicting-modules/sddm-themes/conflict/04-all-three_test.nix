{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./04-all-three;
in
nix-tests.runTests {
  "C04: all three SDDM theme modules must assert" = helpers: {
    "mutual-exclusivity assertion fires with exactly the enabled modules listed" =
      helpers.isTrue (H.hasFailingAssertion "mutually exclusive - enable only one in your host config. Enabled: services.sddm-astronaut, services.sddm-pixie, services.sddm-qylock." config);
    "exactly one mutual-exclusion assertion fails" =
      helpers.isTrue (H.failingCount "mutually exclusive" config == 1);
  };
}
