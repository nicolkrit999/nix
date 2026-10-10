# W10 - gifURL set + skwdWall enabled -> skwdWall wins over the gif branch,
# same short-circuit as the static case: skwdWallActive alone empties the
# wallpaper startup entries before the animated/static branch is considered.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  gifFile = "may_chill.gif";
  config = H.getConfig ./10-gif-skwdwall H.nixosExtraX86;
in
nix-tests.runTests {
  "W10: gifURL set + skwdWall enabled -> skwdWall wins over gif branch" = helpers:
    H.perWm helpers config [
      E.noSupervisor
      E.noDaemon
      E.noDirectMpv
      E.noDirectAwww
      (E.noSpec "gif filename" gifFile)
    ]
    // {
      "services.skwd-deck is enabled" =
        helpers.isTrue (H.skwdDeckEnabled config);
    };
}
