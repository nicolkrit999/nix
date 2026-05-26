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
      helpers.isTrue (H.hasFailingAssertion "mutually exclusive" config);
  };
}
