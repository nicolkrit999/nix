import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-noctalia";
  wm.hyprland = true;
  shells.noctalia = { enable = true; enableOnHyprland = true; };
}
