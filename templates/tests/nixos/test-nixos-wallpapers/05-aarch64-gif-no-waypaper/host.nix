import ../shared/mk-fake-host.nix {
  name = "wp-05-aarch64-gif";
  system = "aarch64-linux";
  constants = import ../shared/base-constants-gif.nix;
  waypaper = false;
}
