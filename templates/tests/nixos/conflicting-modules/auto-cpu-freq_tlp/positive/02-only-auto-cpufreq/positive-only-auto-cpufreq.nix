import ../../shared/mk-fake-host.nix {
  name = "test-positive-only-auto-cpufreq";
  tlp = false;
  "auto-cpufreq" = true;
}
