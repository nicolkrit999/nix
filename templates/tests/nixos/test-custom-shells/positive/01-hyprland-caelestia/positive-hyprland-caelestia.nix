import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-caelestia";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.caelestia = { enable = true; enableOnHyprland = true; };
}
