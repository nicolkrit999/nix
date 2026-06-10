import ../shared/mk-fake-host.nix {
  name = "wp-06-aarch64-waypaper";
  system = "aarch64-linux";
  constants = import ../shared/base-constants-static.nix;
  waypaper = true;
}
