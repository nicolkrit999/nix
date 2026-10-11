import ../shared/mk-fake-host.nix {
  name = "wp-26-lock-desktop-like";
  constants = (import ../shared/base-constants-lock.nix).desktop;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
