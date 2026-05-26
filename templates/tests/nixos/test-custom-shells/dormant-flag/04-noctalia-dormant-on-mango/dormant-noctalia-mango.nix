import ../../shared/mk-fake-host.nix {
  name = "test-dormant-noctalia-mango";
  wm.mango = true;
  shells.noctalia = { enable = false; enableOnMango = true; };
  waybar.mango = true;
}
