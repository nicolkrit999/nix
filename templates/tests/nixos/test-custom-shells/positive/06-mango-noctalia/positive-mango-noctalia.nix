import ../../shared/mk-fake-host.nix {
  name = "test-mango-noctalia";
  wm.mango = true;
  shells.noctalia = { enable = true; enableOnMango = true; };
}
