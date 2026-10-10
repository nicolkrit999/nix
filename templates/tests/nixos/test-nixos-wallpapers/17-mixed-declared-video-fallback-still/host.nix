import ../shared/mk-fake-host.nix {
  name = "wp-17-mixed-declared-video-fallback-still";
  constants = import ../shared/base-constants-mixed-inverse.nix;
  skwdWall = false;
}
