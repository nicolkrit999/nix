import ../shared/mk-fake-host.nix {
  name = "wp-16-mixed-declared-fallback";
  constants = import ../shared/base-constants-mixed-fallback.nix;
  skwdWall = false;
}
