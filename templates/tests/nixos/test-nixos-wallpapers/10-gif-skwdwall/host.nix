import ../shared/mk-fake-host.nix {
  name = "wp-10-gif-skwdwall";
  constants = import ../shared/base-constants-gif.nix;
  skwdWall = true;
}
