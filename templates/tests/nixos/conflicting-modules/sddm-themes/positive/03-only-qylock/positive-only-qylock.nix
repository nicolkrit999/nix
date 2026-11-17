import ../../shared/mk-fake-host.nix {
  name = "test-positive-only-qylock";
  "sddm-astronaut" = false;
  "sddm-pixie" = false;
  "sddm-qylock" = true;
}
