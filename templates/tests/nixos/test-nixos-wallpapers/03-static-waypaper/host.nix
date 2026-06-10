import ../shared/mk-fake-host.nix {
  name = "wp-03-static-waypaper";
  constants = import ../shared/base-constants-static.nix;
  waypaper = true;
}
