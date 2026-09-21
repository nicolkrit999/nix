import ../shared/mk-fake-host.nix {
  name = "wp-02-gif-no-skwdwall";
  constants = import ../shared/base-constants-gif.nix;
  skwdWall = false;
}
