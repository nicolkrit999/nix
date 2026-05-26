# C01 — Both tlp and auto-cpufreq enabled simultaneously.
# Expected: mutual-exclusivity assertion in auto-cpufreq.nix fires.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-both-power-services;
in
nix-tests.runTests {
  "C01: tlp + auto-cpufreq must assert" = helpers: {
    "mutual-exclusivity assertion fires" =
      helpers.isTrue (H.hasFailingAssertion "mutually exclusive" config);
  };
}
