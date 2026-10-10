# W05 - aarch64-linux, static+gif wallpaper, skwdWall disabled
# Mirror of W02 on aarch64. Gif dispatched as "*=video:" via the supervisor,
# no awww-daemon; static used by GNOME/KDE.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  lib = H.lib;
  config = H.getConfig ./05-aarch64-gif-no-skwdwall H.nixosExtraAarch64;
  hm = H.getHm config;

  gifFile = "may_chill.gif";

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W05: aarch64 gif+static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.noDaemon
      (E.spec "*=video: (gif path)" "*=video:")
      (E.spec "gif filename" gifFile)
      E.noDirectAwww
      E.noDirectMpv
    ]
    // {
      "gnome uses static store path (not gifURL)" =
        helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
      "kde plasma wallpaper list non-empty (static)" =
        helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
    };
}
