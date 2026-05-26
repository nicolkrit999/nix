import ../../shared/mk-fake-host.nix {
  name = "test-conflict-both-sddm";
  "sddm-astronaut" = true;
  "sddm-pixie" = true;
}
