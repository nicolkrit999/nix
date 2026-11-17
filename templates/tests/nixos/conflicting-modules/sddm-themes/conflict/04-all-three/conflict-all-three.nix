import ../../shared/mk-fake-host.nix {
  name = "test-conflict-all-three";
  "sddm-astronaut" = true;
  "sddm-pixie" = true;
  "sddm-qylock" = true;
}
