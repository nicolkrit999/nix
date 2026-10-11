import ../shared/mk-fake-host.nix {
  name = "wp-27-lock-laptop-like";
  constants = (import ../shared/base-constants-lock.nix).laptop;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
