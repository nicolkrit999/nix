import ../shared/mk-fake-host.nix {
  name = "wp-32-lock-nostar-one";
  constants = (import ../shared/base-constants-lock.nix).noStarOne;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
