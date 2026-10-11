import ../../shared/mk-fake-host.nix {
  name = "test-consumers-hyprland-no-shell";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
}
