import ../../shared/mk-fake-host.nix {
  name = "test-dormant-caelestia-hyprland";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.caelestia = { enable = false; enableOnHyprland = true; };
  waybar.hyprland = true;
}
