# P01 — Only tlp enabled. Expected: clean eval, services.tlp active, auto-cpufreq off.
{ nix-tests }:
let
  H = import ../shared/eval-scenario.nix;
  config = H.getConfig ./01-only-tlp;
in
nix-tests.runTests {
  "P01: only tlp enabled" = helpers: {
    "mutual-exclusivity assertion does NOT fire" =
      helpers.isFalse (H.hasFailingAssertion "mutually exclusive" config);
    "services.tlp.enable is true" =
      helpers.isTrue config.services.tlp.enable;
    "programs.auto-cpufreq.enable is false" =
      helpers.isFalse config.programs.auto-cpufreq.enable;
  };
}
