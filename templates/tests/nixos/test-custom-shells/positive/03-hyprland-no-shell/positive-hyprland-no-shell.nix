import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-no-shell";
  wm.hyprland = true;
  waybar.hyprland = true;
}
