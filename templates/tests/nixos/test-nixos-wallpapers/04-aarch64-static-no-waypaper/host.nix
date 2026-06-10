import ../shared/mk-fake-host.nix {
  name = "wp-04-aarch64-static";
  system = "aarch64-linux";
  constants = import ../shared/base-constants-static.nix;
  waypaper = false;
}
