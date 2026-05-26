# P02 — Only auto-cpufreq enabled. Expected: clean eval, auto-cpufreq active, tlp off.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./02-only-auto-cpufreq;
in
nix-tests.runTests {
  "P02: only auto-cpufreq enabled" = helpers: {
    "mutual-exclusivity assertion does NOT fire" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "programs.auto-cpufreq.enable is true" =
      helpers.isTrue config.programs.auto-cpufreq.enable;
    "services.tlp.enable is false" =
      helpers.isFalse config.services.tlp.enable;
  };
}
