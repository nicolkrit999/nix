import ../shared/mk-fake-host.nix {
  name = "wp-15-named-monitor-video";
  constants = import ../shared/base-constants-named-monitor-video.nix;
  waypaper = false;
}
