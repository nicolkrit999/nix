# W14 - videoURL set + skwdWall enabled -> skwdWall wins over the video branch,
# same as W10 does for gif. skwdWallActive short-circuits before the
# video/gif/static priority chain is even evaluated.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  videoFile = "loop.mp4";
  config = H.getConfig ./14-video-skwdwall H.nixosExtraX86;
in
nix-tests.runTests {
  "W14: videoURL set + skwdWall enabled -> skwdWall wins over video branch" = helpers:
    H.perWm helpers config [
      E.noSupervisor
      E.noDaemon
      E.noDirectMpv
      (E.noSpec "video filename" videoFile)
    ]
    // {
      "services.skwd-deck is enabled" =
        helpers.isTrue (H.skwdDeckEnabled config);
    };
}
