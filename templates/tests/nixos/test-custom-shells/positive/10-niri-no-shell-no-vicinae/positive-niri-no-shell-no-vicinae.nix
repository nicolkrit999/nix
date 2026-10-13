import ../../shared/mk-fake-host.nix {
  name = "test-niri-no-shell-no-vicinae";
  wm.niri = true;
  vicinae = false;
}
