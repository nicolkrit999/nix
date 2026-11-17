import ../../shared/mk-fake-host.nix {
  name = "test-conflict-pixie-qylock";
  "sddm-astronaut" = false;
  "sddm-pixie" = true;
  "sddm-qylock" = true;
}
