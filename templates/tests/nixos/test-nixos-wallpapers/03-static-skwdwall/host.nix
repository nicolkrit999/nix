import ../shared/mk-fake-host.nix {
  name = "wp-03-static-skwdwall";
  constants = import ../shared/base-constants-static.nix;
  skwdWall = true;
}
