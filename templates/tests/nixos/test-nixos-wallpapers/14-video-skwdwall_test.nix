# W14 - videoURL set + skwdWall enabled -> skwdWall wins over the video branch,
# same as W10 does for gif. skwdWallActive short-circuits before the
# video/gif/static priority chain is even evaluated.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  videoFile = "loop.mp4";
  config = H.getConfig ./14-video-skwdwall H.nixosExtraX86;
in
nix-tests.runTests {
  "W14: videoURL set + skwdWall enabled -> skwdWall wins over video branch" = helpers: {
    "hyprland exec does NOT contain awww-daemon (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain mpvpaper (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas "mpvpaper" config);
    "hyprland exec does NOT contain video filename (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas videoFile config);
    "mango exec does NOT contain mpvpaper" =
      helpers.isFalse (H.mangoExecHas "mpvpaper" config);
    "niri spawn does NOT contain mpvpaper" =
      helpers.isFalse (H.niriSpawnHas "mpvpaper" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
  };
}
