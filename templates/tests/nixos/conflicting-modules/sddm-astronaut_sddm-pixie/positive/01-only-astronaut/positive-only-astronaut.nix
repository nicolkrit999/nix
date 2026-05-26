import ../../shared/mk-fake-host.nix {
  name = "test-positive-only-astronaut";
  "sddm-astronaut" = true;
  "sddm-pixie" = false;
}
