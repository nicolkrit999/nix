import ../../shared/mk-fake-host.nix {
  name = "test-conflict-two-shells-hyprland";
  wm.hyprland = true;
  shells.caelestia = { enable = true; enableOnHyprland = true; };
  shells.noctalia = { enable = true; enableOnHyprland = true; };
}
