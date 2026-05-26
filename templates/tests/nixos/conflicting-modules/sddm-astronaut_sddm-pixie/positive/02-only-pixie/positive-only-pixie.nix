import ../../shared/mk-fake-host.nix {
  name = "test-positive-only-pixie";
  "sddm-astronaut" = false;
  "sddm-pixie" = true;
}
