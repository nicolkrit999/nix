import ../shared/mk-fake-host.nix {
  name = "wp-14-video-waypaper";
  constants = import ../shared/base-constants-video.nix;
  waypaper = true;
}
