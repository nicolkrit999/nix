import ../../shared/mk-fake-host.nix {
  name = "test-dormant-caelestia-hyprland";
  wm.hyprland = true;
  shells.caelestia = { enable = false; enableOnHyprland = true; };
  waybar.hyprland = true;
}
