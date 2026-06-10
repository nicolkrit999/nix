import ../shared/mk-fake-host.nix {
  name = "wp-07-noctalia-hyprland-waypaper";
  constants = import ../shared/base-constants-static.nix;
  waypaper = true;
  shells.noctalia = {
    enable = true;
    enableOnHyprland = true;
    enableOnNiri = false;
    enableOnMango = false;
  };
}
