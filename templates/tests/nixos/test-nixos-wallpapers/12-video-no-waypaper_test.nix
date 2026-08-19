# W12 - x86_64, mixed static+video wallpaper, waypaper disabled
# videoURL is set (gifURL empty). Expected: WMs dispatch the VIDEO via mpvpaper
# (video wins over static), wildcard monitor -> "ALL" for mpvpaper's -o flag.
# GNOME dconf background still uses the static wallpaperURL (DEs never see videoURL).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./12-video-no-waypaper H.nixosExtraX86;
  hm = H.getHm config;

  # fetchurl derives the store path suffix from the URL's basename, not the
  # sha256. "loop.mp4" comes from the videoURL basename in base-constants-video.nix.
  videoFile = "loop.mp4";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W12: x86_64 video+static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains mpvpaper -f -o loop ALL (video wins over static)" =
      helpers.isTrue (H.hyprExecHas "mpvpaper -f -o loop ALL" config);
    "hyprland exec contains video filename" =
      helpers.isTrue (H.hyprExecHas videoFile config);
    "hyprland exec does NOT contain awww img" =
      helpers.isFalse (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains mpvpaper -f -o loop ALL" =
      helpers.isTrue (H.mangoExecHas "mpvpaper -f -o loop ALL" config);
    "mango exec does NOT contain awww img" =
      helpers.isFalse (H.mangoExecHas "awww img" config);
    "niri spawn contains mpvpaper -f -o loop ALL" =
      helpers.isTrue (H.niriSpawnHas "mpvpaper -f -o loop ALL" config);
    "niri spawn does NOT contain awww img" =
      helpers.isFalse (H.niriSpawnHas "awww img" config);
    # GNOME always uses the static wallpaperURL (videoURL is WM-only)
    "gnome dconf background picture-uri references a store path (not videoURL directly)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
    "kde plasma wallpaper list is non-empty" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
