import ../shared/mk-fake-host.nix {
  name = "wp-02-gif-no-waypaper";
  constants = import ../shared/base-constants-gif.nix;
  waypaper = false;
}
