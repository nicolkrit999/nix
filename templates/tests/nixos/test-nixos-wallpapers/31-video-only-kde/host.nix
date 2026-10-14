import ../shared/mk-fake-host.nix {
  name = "wp-31-video-only-kde";
  constants = import ../shared/base-constants-video-only-primary.nix;
  minimal = true;
  gnome = false;
  kde = true;
  wms = [ ];
}
