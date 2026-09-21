import ../shared/mk-fake-host.nix {
  name = "wp-14-video-skwdwall";
  constants = import ../shared/base-constants-video.nix;
  skwdWall = true;
}
