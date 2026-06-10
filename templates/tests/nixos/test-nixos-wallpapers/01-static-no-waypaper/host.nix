import ../shared/mk-fake-host.nix {
  name = "wp-01-static-no-waypaper";
  constants = import ../shared/base-constants-static.nix;
  waypaper = false;
}
