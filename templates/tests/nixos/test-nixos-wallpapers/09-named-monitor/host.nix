import ../shared/mk-fake-host.nix {
  name = "wp-09-named-monitor";
  constants = import ../shared/base-constants-named-monitor.nix;
  waypaper = false;
}
