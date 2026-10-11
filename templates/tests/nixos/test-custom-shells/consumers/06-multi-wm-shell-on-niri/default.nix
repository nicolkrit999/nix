import ../../shared/mk-fake-host.nix {
  name = "test-consumers-multi-wm";
  wm = { hyprland = true; niri = true; mango = true; };
  wallpapers = import ../../shared/one-wallpaper.nix;
  shells.noctalia = { enable = true; enableOnNiri = true; };
}
