import ../shared/mk-fake-host.nix {
  name = "wp-35-lock-catppuccin-sizes";
  constants = (import ../shared/base-constants-lock.nix).desktopCatppuccinSizes;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
