import ../shared/mk-fake-host.nix {
  name = "wp-22-nostar-wm";
  constants = import ../shared/base-constants-no-star.nix;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
