# W01 - x86_64, static-only wallpaper on "*" (fallback), skwdWall disabled.
# Expected: every WM (hyprland, mango, niri) runs its own <wm>-wallpaperd with a
# single "*=image:" spec and starts awww-daemon (a still is used), KDE/GNOME use
# the static path, and services.skwd-deck is absent from the build.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./01-static-no-skwdwall H.nixosExtraX86;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W01: x86_64 static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "*=image:" "*=image:")
      (E.noSpec "video entry" "=video:")
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "kde plasma wallpaper list is non-empty (old static logic active)" =
        helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
      "kde wallpaperCustomPlugin is unset" =
        helpers.isTrue (H.kdeWallpaperCustomPlugin config == null);
      "gnome dconf background picture-uri is set (always static, skwdWall-independent)" =
        helpers.isTrue (H.isStillUri
          (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
      "services.skwd-deck is NOT enabled (skwdWall disabled)" =
        helpers.isFalse (H.skwdDeckEnabled config);
      "skwd-paper-plasma NOT in home packages (skwdWall disabled)" =
        helpers.isFalse (H.hmHasPkg "skwd-paper-plasma" config);
    };
}
