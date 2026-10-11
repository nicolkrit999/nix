import ../../shared/mk-fake-host.nix {
  name = "test-consumers-noctalia-niri";
  wm.niri = true;
  shells.noctalia = { enable = true; enableOnNiri = true; };
}
