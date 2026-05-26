import ../../shared/mk-fake-host.nix {
  name = "test-mango-no-shell";
  wm.mango = true;
  waybar.mango = true;
}
