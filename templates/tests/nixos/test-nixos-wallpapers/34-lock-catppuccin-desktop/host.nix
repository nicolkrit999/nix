import ../shared/mk-fake-host.nix {
  name = "wp-34-lock-catppuccin-desktop";
  constants = (import ../shared/base-constants-lock.nix).desktopCatppuccin;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
