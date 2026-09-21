import ../shared/mk-fake-host.nix {
  name = "wp-07-noctalia-hyprland-skwdwall";
  constants = import ../shared/base-constants-static.nix;
  skwdWall = true;
  shells.noctalia = {
    enable = true;
    enableOnHyprland = true;
    enableOnNiri = false;
    enableOnMango = false;
  };
}
