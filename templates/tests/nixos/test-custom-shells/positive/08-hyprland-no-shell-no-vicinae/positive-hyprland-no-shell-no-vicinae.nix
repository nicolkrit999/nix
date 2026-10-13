import ../../shared/mk-fake-host.nix {
  name = "test-hyprland-no-shell-no-vicinae";
  wm.hyprland = true;
  vicinae = false;
}
