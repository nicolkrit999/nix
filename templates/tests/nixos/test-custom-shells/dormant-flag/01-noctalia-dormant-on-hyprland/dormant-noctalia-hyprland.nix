import ../../shared/mk-fake-host.nix {
  name = "test-dormant-noctalia-hyprland";
  wm.hyprland = true;
  wallpapers = import ../../shared/one-wallpaper.nix;
  # enable=false but enableOnHyprland=true — the dormant-flag pattern.
  # Every consumer must behave as "no shell", not "shell suppressed".
  shells.noctalia = { enable = false; enableOnHyprland = true; };
}
