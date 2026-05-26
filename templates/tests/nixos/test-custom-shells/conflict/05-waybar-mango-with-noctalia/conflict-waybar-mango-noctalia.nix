import ../../shared/mk-fake-host.nix {
  name = "test-conflict-waybar-mango-noctalia";
  wm.mango = true;
  shells.noctalia = { enable = true; enableOnMango = true; };
  waybar.mango = true;
}
