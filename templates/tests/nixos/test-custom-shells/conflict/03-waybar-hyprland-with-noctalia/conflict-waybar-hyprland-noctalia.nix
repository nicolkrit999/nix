import ../../shared/mk-fake-host.nix {
  name = "test-conflict-waybar-hyprland-noctalia";
  wm.hyprland = true;
  shells.noctalia = { enable = true; enableOnHyprland = true; };
  waybar.hyprland = true;
}
