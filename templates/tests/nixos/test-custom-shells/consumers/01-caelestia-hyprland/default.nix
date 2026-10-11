import ../../shared/mk-fake-host.nix {
  name = "test-consumers-caelestia-hyprland";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.caelestia = { enable = true; enableOnHyprland = true; };
}
