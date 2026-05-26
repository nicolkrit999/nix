import ../../shared/mk-fake-host.nix {
  name = "test-niri-noctalia";
  wm.niri = true;
  shells.noctalia = { enable = true; enableOnNiri = true; };
}
