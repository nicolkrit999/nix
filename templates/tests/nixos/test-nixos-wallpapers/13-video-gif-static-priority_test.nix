# W13 - x86_64, wallpaperURL + gifURL + videoURL all set, waypaper disabled
# Full priority chain: video > gif > static. Expected: WMs dispatch the VIDEO
# via mpvpaper, never the gif or static path.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./13-video-gif-static-priority H.nixosExtraX86;
  hm = H.getHm config;

  # fetchurl derives the store path suffix from the URL's basename, not the sha256.
  videoFile = "loop.mp4";
  gifFile = "may_chill.gif";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W13: x86_64 video+gif+static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains mpvpaper -f -o \"loop mute=yes\" ALL (video wins over gif+static)" =
      helpers.isTrue (H.hyprExecHas "mpvpaper -f -o \\\"loop mute=yes\\\" ALL" config);
    "hyprland exec contains video filename" =
      helpers.isTrue (H.hyprExecHas videoFile config);
    "hyprland exec does NOT contain gif filename (video beats gif)" =
      helpers.isFalse (H.hyprExecHas gifFile config);
    "hyprland exec does NOT contain awww img" =
      helpers.isFalse (H.hyprExecHas "awww img" config);
    "mango exec contains mpvpaper -f -o \"loop mute=yes\" ALL" =
      helpers.isTrue (H.mangoExecHas "mpvpaper -f -o \"loop mute=yes\" ALL" config);
    "mango exec does NOT contain gif filename" =
      helpers.isFalse (H.mangoExecHas gifFile config);
    "niri spawn contains mpvpaper -f -o \"loop mute=yes\" ALL" =
      helpers.isTrue (H.niriSpawnHas "mpvpaper -f -o \"loop mute=yes\" ALL" config);
    "niri spawn does NOT contain gif filename" =
      helpers.isFalse (H.niriSpawnHas gifFile config);
    # GNOME/KDE always use the static wallpaperURL regardless of gif/video
    "gnome dconf background picture-uri references a store path" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
    "kde plasma wallpaper list is non-empty" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
