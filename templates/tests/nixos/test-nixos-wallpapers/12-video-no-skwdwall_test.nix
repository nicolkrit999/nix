# W12 - x86_64, static+video wallpaper on "*", skwdWall disabled.
# Video wins over static: single "*=video:" spec per WM, no awww-daemon.
# GNOME dconf background still uses the static wallpaperURL (DEs never see videoURL).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./12-video-no-skwdwall H.nixosExtraX86;
  hm = H.getHm config;

  # fetchurl derives the store path suffix from the URL's basename, not the
  # sha256. "loop.mp4" comes from the videoURL in base-constants-video.nix.
  videoFile = "loop.mp4";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W12: x86_64 video+static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.noDaemon
      (E.spec "*=video: (video wins over static)" "*=video:")
      (E.spec "video filename" videoFile)
      (E.noSpec "image entry" "=image:")
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "gnome dconf background picture-uri references a store path (not videoURL directly)" =
        helpers.isTrue (H.isStillUri (builtins.toString gnomeBgUri));
      "kde plasma wallpaper list is non-empty" =
        helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
    };
}
