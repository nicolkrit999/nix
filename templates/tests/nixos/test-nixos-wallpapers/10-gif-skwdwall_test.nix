# W10 - gifURL set + skwdWall enabled → skwdWall wins over the gif branch,
# same short-circuit as the static case: skwdWallActive alone empties
# wallpaperCmds/wallpaperExecs/wallpaperSpawns before the animated/static
# branch is ever considered.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  gifHash = "1v3h995fifxcdvrizr5n99h0bmja7khzi89bh33d869psrjc4ssp";
  config = H.getConfig ./10-gif-skwdwall H.nixosExtraX86;
in
nix-tests.runTests {
  "W10: gifURL set + skwdWall enabled -> skwdWall wins over gif branch" = helpers: {
    "hyprland exec does NOT contain awww-daemon (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain mpvpaper (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas "mpvpaper" config);
    "hyprland exec does NOT contain gif sha fragment (skwdWall wins)" =
      helpers.isFalse (H.hyprExecHas gifHash config);
    "mango exec does NOT contain awww-daemon (skwdWall wins)" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn does NOT contain awww-daemon (skwdWall wins)" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
  };
}
