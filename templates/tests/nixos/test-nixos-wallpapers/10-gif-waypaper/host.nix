import ../shared/mk-fake-host.nix {
  name = "wp-10-gif-waypaper";
  constants = import ../shared/base-constants-gif.nix;
  waypaper = true;
}
