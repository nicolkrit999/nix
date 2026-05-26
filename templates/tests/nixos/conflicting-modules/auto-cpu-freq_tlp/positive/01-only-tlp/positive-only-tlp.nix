import ../../shared/mk-fake-host.nix {
  name = "test-positive-only-tlp";
  tlp = true;
  "auto-cpufreq" = false;
}
