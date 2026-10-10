import ../shared/mk-fake-host.nix {
  name = "wp-18-two-declared-no-fallback";
  constants = import ../shared/base-constants-two-declared.nix;
  skwdWall = false;
}
