import ../shared/mk-fake-host.nix {
  name = "wp-23-nostar-gnome";
  constants = import ../shared/base-constants-no-star.nix;
  minimal = true;
  wms = [ ];
  gnome = true;
  kde = false;
}
