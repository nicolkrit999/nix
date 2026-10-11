import ../../shared/mk-fake-host.nix {
  name = "test-consumers-dormant-hyprland";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.noctalia = { enable = false; enableOnHyprland = true; };
  shells.caelestia = { enable = false; enableOnHyprland = true; };
}
