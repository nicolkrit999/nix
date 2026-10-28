import ../shared/mk-fake-host.nix {
  name = "wp-35-lock-catppuccin-sizes";
  constants = (import ../shared/base-constants-lock.nix).desktopCatppuccinSizes;
  hyprlock = (import ../shared/base-constants-lock.nix).lockSizes;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
