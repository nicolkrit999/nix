import ../../shared/mk-fake-host.nix {
  name = "test-conflict-astronaut-qylock";
  "sddm-astronaut" = true;
  "sddm-pixie" = false;
  "sddm-qylock" = true;
}
