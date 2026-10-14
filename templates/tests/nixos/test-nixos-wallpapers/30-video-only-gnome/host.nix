import ../shared/mk-fake-host.nix {
  name = "wp-30-video-only-gnome";
  constants = import ../shared/base-constants-video-only-primary.nix;
  minimal = true;
  gnome = true;
  kde = false;
  wms = [ ];
}
