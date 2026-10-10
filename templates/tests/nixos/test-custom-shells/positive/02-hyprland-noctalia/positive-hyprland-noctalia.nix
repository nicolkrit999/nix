import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-noctalia";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.noctalia = { enable = true; enableOnHyprland = true; };
}
