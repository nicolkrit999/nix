import ../shared/mk-fake-host.nix {
  name = "wp-01-static-no-skwdwall";
  constants = import ../shared/base-constants-static.nix;
  skwdWall = false;
}
