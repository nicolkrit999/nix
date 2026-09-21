import ../shared/mk-fake-host.nix {
  name = "wp-08-all-shells-skwdwall";
  constants = import ../shared/base-constants-static.nix;
  skwdWall = true;
  shells = {
    # caelestia owns hyprland wallpaper
    caelestia = {
      enable = true;
      enableOnHyprland = true;
    };
    # noctalia owns mango + niri wallpaper; NOT hyprland (caelestia is there)
    noctalia = {
      enable = true;
      enableOnHyprland = false;
      enableOnMango = true;
      enableOnNiri = true;
    };
  };
}
