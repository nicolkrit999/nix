# W14 - videoURL set + waypaper enabled -> waypaper wins over the video branch,
# same as W10 does for gif. waypaperActive short-circuits before the
# video/gif/static priority chain is even evaluated.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  videoFile = "loop.mp4";
  config = H.getConfig ./14-video-waypaper H.nixosExtraX86;
in
nix-tests.runTests {
  "W14: videoURL set + waypaper enabled -> waypaper wins over video branch" = helpers: {
    "hyprland exec contains waypaper --restore (waypaper branch beats video branch)" =
      helpers.isTrue (H.hyprExecHas "waypaper --restore" config);
    "hyprland exec does NOT contain awww-daemon (waypaper wins)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain mpvpaper (waypaper wins)" =
      helpers.isFalse (H.hyprExecHas "mpvpaper" config);
    "hyprland exec does NOT contain video filename (waypaper wins)" =
      helpers.isFalse (H.hyprExecHas videoFile config);
    "mango exec contains waypaper --restore" =
      helpers.isTrue (H.mangoExecHas "waypaper --restore" config);
    "mango exec does NOT contain mpvpaper" =
      helpers.isFalse (H.mangoExecHas "mpvpaper" config);
    "niri spawn contains waypaper --restore" =
      helpers.isTrue (H.niriSpawnHas "waypaper --restore" config);
    "niri spawn does NOT contain mpvpaper" =
      helpers.isFalse (H.niriSpawnHas "mpvpaper" config);
    "waypaper IS in home packages" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
  };
}
