import ../shared/mk-fake-host.nix {
  name = "wp-11-noctalia-dormant";
  constants = import ../shared/base-constants-static.nix;
  waypaper = false;
  shells.noctalia = {
    enable = true;
    enableOnHyprland = false;
    enableOnNiri = false;
    enableOnMango = false;
  };
}
