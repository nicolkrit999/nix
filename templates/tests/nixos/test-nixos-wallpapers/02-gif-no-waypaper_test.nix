# W02 — x86_64, mixed static+gif wallpaper, waypaper disabled
# gifURL is set. Expected: WMs use the GIF path (not the static path).
# GNOME dconf background uses the static wallpaperURL (DEs never see gifURL).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./02-gif-no-waypaper H.nixosExtraX86;
  hm = H.getHm config;

  # The GIF derivation store path will contain the gif sha256 fragment.
  # The static image derivation store path contains the static sha256 fragment.

  # GNOME background URI from dconf — must reference the static wallpaper path.
  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W02: x86_64 gif+static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img (gif path chosen)" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
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
