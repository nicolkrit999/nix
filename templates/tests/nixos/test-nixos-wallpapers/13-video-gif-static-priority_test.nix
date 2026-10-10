# W13 - x86_64, wallpaperURL + gifURL + videoURL all set on "*", skwdWall disabled
# Full priority chain: video > gif > static. Every WM gets one "*=video:" spec
# with the video, never the gif or static path, and no awww-daemon.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  lib = H.lib;
  config = H.getConfig ./13-video-gif-static-priority H.nixosExtraX86;
  hm = H.getHm config;

  videoFile = "loop.mp4";
  gifFile = "may_chill.gif";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W13: x86_64 video+gif+static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.noDaemon
      (E.spec "*=video: (video wins over gif+static)" "*=video:")
      (E.spec "video filename" videoFile)
      (E.noSpec "gif filename (video beats gif)" gifFile)
      (E.noSpec "image entry" "=image:")
      E.noDirectAwww
    ]
    // {
      "gnome dconf background picture-uri references a store path" =
        helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
      "kde plasma wallpaper list is non-empty" =
        helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
    };
}
