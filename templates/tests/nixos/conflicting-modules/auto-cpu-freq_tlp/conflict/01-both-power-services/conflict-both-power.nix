import ../../shared/mk-fake-host.nix {
  name = "test-conflict-both-power";
  tlp = true;
  "auto-cpufreq" = true;
}
