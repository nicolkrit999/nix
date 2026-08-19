import ../shared/mk-fake-host.nix {
  name = "wp-12-video-no-waypaper";
  constants = import ../shared/base-constants-video.nix;
  waypaper = false;
}
