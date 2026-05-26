import ../../shared/mk-fake-host.nix {
  name = "test-conflict-waybar-hyprland-caelestia";
  wm.hyprland = true;
  shells.caelestia = { enable = true; enableOnHyprland = true; };
  waybar.hyprland = true;
}
