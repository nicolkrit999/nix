import ../shared/mk-fake-host.nix {
  name = "wp-33-lock-nostar-three";
  constants = (import ../shared/base-constants-lock.nix).noStarThree;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
