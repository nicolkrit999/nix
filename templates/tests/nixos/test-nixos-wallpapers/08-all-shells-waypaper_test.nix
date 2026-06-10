# W08 — caelestia on hyprland + noctalia on mango+niri, waypaper enabled
# Every WM has a shell owning its wallpaper → no awww, no waypaper --restore in any WM.
# waypaper package still installed (module is enabled regardless of WM behavior).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./08-all-shells-waypaper H.nixosExtraX86;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W08: caelestia on hyprland + noctalia on mango+niri + waypaper enabled" = helpers: {
    # Hyprland: caelestia active → shell owns wallpaper
    "hyprland exec does NOT contain awww-daemon (caelestia owns it)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain waypaper --restore (caelestia owns it)" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    # Mango: noctalia active → shell owns wallpaper
    "mango exec does NOT contain awww-daemon (noctalia owns it)" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "mango exec does NOT contain waypaper --restore (noctalia owns it)" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    # Niri: noctalia active → shell owns wallpaper
    "niri spawn does NOT contain awww-daemon (noctalia owns it)" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "niri spawn does NOT contain waypaper --restore (noctalia owns it)" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
    # waypaper package still installed even though no WM uses it directly
    "waypaper IS in home packages (module enabled)" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
    # linux-wallpaperengine also installed (x86_64 + waypaper enabled)
    "linux-wallpaperengine IS in home packages (x86_64 + waypaper enabled)" =
      helpers.isTrue (H.hmHasPkg "linux-wallpaperengine" config);
    # DEs still use static wallpaper
    "gnome dconf background is set (static wallpaper)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/"
        (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
    "kde plasma wallpaper list non-empty" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
