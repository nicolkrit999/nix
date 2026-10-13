import ../../shared/mk-fake-host.nix {
  name = "test-mango-no-shell-no-vicinae";
  wm.mango = true;
  vicinae = false;
}
