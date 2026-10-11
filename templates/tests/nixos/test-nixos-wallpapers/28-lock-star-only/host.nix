import ../shared/mk-fake-host.nix {
  name = "wp-28-lock-star-only";
  constants = (import ../shared/base-constants-lock.nix).starOnly;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
