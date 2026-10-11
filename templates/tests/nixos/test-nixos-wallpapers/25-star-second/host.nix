import ../shared/mk-fake-host.nix {
  name = "wp-25-star-second";
  constants = import ../shared/base-constants-star-second.nix;
  minimal = true;
  wms = [ ];
  gnome = false;
  kde = false;
}
