import ../../shared/mk-fake-host.nix {
  name = "test-niri-no-shell";
  wm.niri = true;
  waybar.niri = true;
}
