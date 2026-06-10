# W03 — x86_64, static wallpaper, waypaper ENABLED
# waypaper.enable = true. Expected: all WMs use "waypaper --restore" instead
# of awww. linux-wallpaperengine IS present (x86_64 + waypaper enabled).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./03-static-waypaper H.nixosExtraX86;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W03: x86_64 static wallpaper, waypaper enabled" = helpers: {
    "hyprland exec contains waypaper --restore" =
      helpers.isTrue (H.hyprExecHas "waypaper --restore" config);
    "hyprland exec does NOT contain awww-daemon" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "mango exec contains waypaper --restore" =
      helpers.isTrue (H.mangoExecHas "waypaper --restore" config);
    "mango exec does NOT contain awww-daemon" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn contains waypaper --restore" =
      helpers.isTrue (H.niriSpawnHas "waypaper --restore" config);
    "niri spawn does NOT contain awww-daemon" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "linux-wallpaperengine IS in home packages (x86_64 + waypaper enabled)" =
      helpers.isTrue (H.hmHasPkg "linux-wallpaperengine" config);
    "waypaper IS in home packages" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
    # DEs still use static wallpaper regardless of waypaper mode
    "gnome dconf background picture-uri is set" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/"
        (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
    "kde plasma wallpaper list is non-empty" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
