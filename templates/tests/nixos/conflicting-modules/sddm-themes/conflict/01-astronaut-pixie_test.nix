{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-astronaut-pixie;
in
nix-tests.runTests {
  "C01: sddm-astronaut + sddm-pixie must assert" = helpers: {
    "mutual-exclusivity assertion fires with exactly the enabled modules listed" =
      helpers.isTrue (H.hasFailingAssertion "mutually exclusive - enable only one in your host config. Enabled: services.sddm-astronaut, services.sddm-pixie." config);
    "exactly one mutual-exclusion assertion fails" =
      helpers.isTrue (H.failingCount "mutually exclusive" config == 1);
    "Enabled list does not name services.sddm-qylock" =
      helpers.isFalse (H.hasFailingAssertion "Enabled: services.sddm-qylock" config);
  };
}
