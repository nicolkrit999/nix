import ../../shared/mk-fake-host.nix {
  name = "test-conflict-waybar-niri-noctalia";
  wm.niri = true;
  shells.noctalia = { enable = true; enableOnNiri = true; };
  waybar.niri = true;
}
