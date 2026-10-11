import ../shared/mk-fake-host.nix {
  name = "wp-24-nostar-kde";
  constants = import ../shared/base-constants-no-star.nix;
  minimal = true;
  wms = [ ];
  gnome = false;
  kde = true;
}
