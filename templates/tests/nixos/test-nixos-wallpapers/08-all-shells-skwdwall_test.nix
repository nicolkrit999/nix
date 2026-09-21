# W08 - caelestia on hyprland + noctalia on mango+niri, skwdWall ENABLED
# Every WM already has a shell owning its wallpaper, and skwdWall is also
# enabled - both signals point the same direction (no awww anywhere).
# KDE still swaps to wallpaperCustomPlugin, GNOME is unaffected.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./08-all-shells-skwdwall H.nixosExtraX86;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W08: caelestia on hyprland + noctalia on mango+niri + skwdWall enabled" = helpers: {
    "hyprland exec does NOT contain awww-daemon (caelestia + skwdWall both suppress it)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "mango exec does NOT contain awww-daemon (noctalia + skwdWall both suppress it)" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn does NOT contain awww-daemon (noctalia + skwdWall both suppress it)" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
    "kde wallpaperCustomPlugin.plugin is org.skwd.wall.plasma" =
      helpers.isTrue (H.kdeWallpaperCustomPlugin config == "org.skwd.wall.plasma");
    "skwd-paper-plasma IS in home packages (x86_64 + skwdWall enabled)" =
      helpers.isTrue (H.hmHasPkg "skwd-paper-plasma" config);
    # GNOME is not part of the skwdWall toggle
    "gnome dconf background is set (static wallpaper, unaffected by skwdWall)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/"
        (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
  };
}
