import ../../shared/mk-fake-host.nix {
  name = "test-dormant-noctalia-niri";
  wm.niri = true;
  shells.noctalia = { enable = false; enableOnNiri = true; };
  waybar.niri = true;
}
