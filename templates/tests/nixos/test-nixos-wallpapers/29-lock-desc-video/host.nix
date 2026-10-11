import ../shared/mk-fake-host.nix {
  name = "wp-29-lock-desc-video";
  constants = (import ../shared/base-constants-lock.nix).descAndVideo;
  minimal = true;
  wms = [ "hyprland" ];
  gnome = false;
  kde = false;
}
