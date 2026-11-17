import ../../shared/mk-fake-host.nix {
  name = "test-conflict-astronaut-pixie";
  "sddm-astronaut" = true;
  "sddm-pixie" = true;
  "sddm-qylock" = false;
}
