import ../shared/mk-fake-host.nix {
  name = "wp-21-empty-kde";
  constants = import ../shared/base-constants-empty.nix;
  minimal = true;
  gnome = false;
  wms = [ ];
  kde = true;
}
