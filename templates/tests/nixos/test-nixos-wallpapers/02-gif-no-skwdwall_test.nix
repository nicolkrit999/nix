# W02 - x86_64, static+gif wallpaper on "*" (fallback), skwdWall disabled.
# The gif wins over the static: every WM gets a single "*=video:" spec carrying
# the gif, and awww-daemon is NOT started (no still image is used).
# GNOME dconf background uses the static wallpaperURL (DEs never see gifURL).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  lib = H.lib;
  config = H.getConfig ./02-gif-no-skwdwall H.nixosExtraX86;
  hm = H.getHm config;

  # fetchurl derives the store path suffix from the URL's basename, not the
  # sha256. "may_chill.gif" comes from the gifURL in base-constants-gif.nix.
  gifFile = "may_chill.gif";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W02: x86_64 gif+static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.noDaemon
      (E.spec "*=video: (gif dispatched as video, wildcard fallback)" "*=video:")
      (E.spec "gif filename (gif chosen over static)" gifFile)
      (E.noSpec "image entry" "=image:")
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "gnome dconf background picture-uri references a store path (not gifURL directly)" =
        helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
      "kde plasma wallpaper list is non-empty" =
        helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
    };
}
