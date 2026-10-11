import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-no-shell";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
}
