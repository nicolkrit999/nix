import ../shared/mk-fake-host.nix {
  name = "wp-19-empty-wm";
  constants = import ../shared/base-constants-empty.nix;
  minimal = true;
  gnome = false;
  kde = false;
}
