{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./03-pixie-qylock;
in
nix-tests.runTests {
  "C03: sddm-pixie + sddm-qylock must assert" = helpers: {
    "mutual-exclusivity assertion fires with exactly the enabled modules listed" =
      helpers.isTrue (H.hasFailingAssertion "mutually exclusive - enable only one in your host config. Enabled: services.sddm-pixie, services.sddm-qylock." config);
    "exactly one mutual-exclusion assertion fails" =
      helpers.isTrue (H.failingCount "mutually exclusive" config == 1);
    "Enabled list does not name services.sddm-astronaut" =
      helpers.isFalse (H.hasFailingAssertion "Enabled: services.sddm-astronaut" config);
  };
}
