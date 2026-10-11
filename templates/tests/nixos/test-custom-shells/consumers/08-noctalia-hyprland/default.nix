import ../../shared/mk-fake-host.nix {
  name = "test-consumers-noctalia-hyprland";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.noctalia = { enable = true; enableOnHyprland = true; };
}
