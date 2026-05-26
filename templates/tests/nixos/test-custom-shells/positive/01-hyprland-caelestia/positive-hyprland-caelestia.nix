import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-caelestia";
  wm.hyprland = true;
  shells.caelestia = { enable = true; enableOnHyprland = true; };
}
