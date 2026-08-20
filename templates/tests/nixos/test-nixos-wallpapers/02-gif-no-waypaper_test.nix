# W02 - x86_64, mixed static+gif wallpaper, waypaper disabled
# gifURL is set. Expected: WMs dispatch the GIF via mpvpaper (not awww),
# wildcard monitor -> "ALL" for mpvpaper's -o flag.
# GNOME dconf background uses the static wallpaperURL (DEs never see gifURL).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-gif-no-waypaper H.nixosExtraX86;
  hm = H.getHm config;

  # fetchurl derives the store path suffix from the URL's basename, not the
  # sha256 (the FOD hash only affects the store path prefix). "may_chill.gif"
  # comes from the gifURL basename in base-constants-gif.nix.
  gifFile = "may_chill.gif";

  # GNOME background URI from dconf - must reference the static wallpaper path.
  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W02: x86_64 gif+static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL (gif dispatched via mpvpaper, wildcard monitor)" =
      helpers.isTrue (H.hyprExecHas "mpvpaper -f -o \\\"loop mute=yes panscan=1.0\\\" ALL" config);
    "hyprland exec contains gif filename (gif path chosen over static)" =
      helpers.isTrue (H.hyprExecHas gifFile config);
    "hyprland exec does NOT contain awww img (gif wins over static)" =
      helpers.isFalse (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL" =
      helpers.isTrue (H.mangoExecHas "mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL" config);
    "mango exec does NOT contain awww img" =
      helpers.isFalse (H.mangoExecHas "awww img" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn contains mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL" =
      helpers.isTrue (H.niriSpawnHas "mpvpaper -f -o \"loop mute=yes panscan=1.0\" ALL" config);
    "niri spawn does NOT contain awww img" =
      helpers.isFalse (H.niriSpawnHas "awww img" config);
    "niri spawn does NOT contain waypaper --restore" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
    # GNOME always uses the static wallpaperURL (gifURL is WM-only)
    "gnome dconf background picture-uri references a store path (not gifURL directly)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
    # KDE wallpaper list must not be empty (uses wallpaperURL)
    "kde plasma wallpaper list is non-empty" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
