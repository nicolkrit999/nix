# C01 — Both sddm-astronaut and sddm-pixie enabled simultaneously.
# Expected: mutual-exclusivity assertion in sddm-astronaut.nix fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-both-sddm-themes;
in
nix-tests.runTests {
  "C01: sddm-astronaut + sddm-pixie must assert" = helpers: {
    "mutual-exclusivity assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "services.sddm-astronaut and services.sddm-pixie are mutually exclusive" config);
    "exactly one mutual-exclusion assertion fails" =
      helpers.isTrue (H.failingCount "mutually exclusive" config == 1);
  };
}
