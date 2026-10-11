import ../../shared/mk-fake-host.nix {
  name = "test-consumers-noctalia-mango";
  wm.mango = true;
  shells.noctalia = { enable = true; enableOnMango = true; };
}
