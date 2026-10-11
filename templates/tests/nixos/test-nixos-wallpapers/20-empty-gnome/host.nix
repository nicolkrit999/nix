import ../shared/mk-fake-host.nix {
  name = "wp-20-empty-gnome";
  constants = import ../shared/base-constants-empty.nix;
  minimal = true;
  gnome = true;
  kde = false;
  wms = [ ];
}
