import ../shared/mk-fake-host.nix {
  name = "wp-36-lock-sizes-catppuccin-off";
  constants = (import ../shared/base-constants-lock.nix).desktopSizes;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
