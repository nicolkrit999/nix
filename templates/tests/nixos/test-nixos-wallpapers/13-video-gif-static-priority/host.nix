import ../shared/mk-fake-host.nix {
  name = "wp-13-video-gif-static-priority";
  constants = import ../shared/base-constants-video-priority.nix;
  waypaper = false;
}
