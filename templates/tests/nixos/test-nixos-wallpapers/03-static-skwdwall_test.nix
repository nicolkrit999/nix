# W03 - x86_64, static wallpaper, skwdWall ENABLED
# programs.skwdWall.enable = true. Expected: hyprland/mango/niri drop their
# awww exec entirely (skwdWall owns the wallpaper via skwd-walld), KDE swaps
# its static `wallpaper` list for `wallpaperCustomPlugin`, the
# skwd-paper-plasma package is installed (x86_64), and services.skwd-deck is
# enabled at the system level. GNOME is untouched by skwdWall.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./03-static-skwdwall H.nixosExtraX86;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W03: x86_64 static wallpaper, skwdWall enabled" = helpers: {
    "hyprland exec does NOT contain awww-daemon" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain awww img" =
      helpers.isFalse (H.hyprExecHas "awww img" config);
    "mango exec does NOT contain awww-daemon" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn does NOT contain awww-daemon" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
    "kde wallpaperCustomPlugin.plugin is org.skwd.wall.plasma" =
      helpers.isTrue (H.kdeWallpaperCustomPlugin config == "org.skwd.wall.plasma");
    "kde workspace.wallpaper is unset (null) while skwdWall owns it" =
      helpers.isTrue (hm.programs.plasma.workspace.wallpaper == null);
    "skwd-paper-plasma IS in home packages (x86_64 + skwdWall enabled)" =
      helpers.isTrue (H.hmHasPkg "skwd-paper-plasma" config);
    # GNOME is not part of the skwdWall toggle - still static, unconditionally
    "gnome dconf background picture-uri is set (unaffected by skwdWall)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/"
        (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
  };
}
