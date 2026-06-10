# W05 — aarch64-linux, mixed static+gif wallpaper, waypaper disabled
# Mirror of W02 on aarch64. GIF chosen by WMs; static used by GNOME/KDE.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./05-aarch64-gif-no-waypaper H.nixosExtraAarch64;
  hm = H.getHm config;

  gnomeBgUri = hm.dconf.settings."org/gnome/desktop/background".picture-uri or "";
in
nix-tests.runTests {
  "W05: aarch64 gif+static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img (gif path)" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "gnome uses static store path (not gifURL)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/" (builtins.toString gnomeBgUri));
    "kde plasma wallpaper list non-empty (static)" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
