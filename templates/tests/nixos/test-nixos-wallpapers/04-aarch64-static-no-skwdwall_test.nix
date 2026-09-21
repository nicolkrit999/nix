# W04 - aarch64-linux, static-only wallpaper, skwdWall disabled
# Mirror of W01 on aarch64. Expected: same awww behavior as x86_64 for WMs,
# and services.skwd-deck absent from the build.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./04-aarch64-static-no-skwdwall H.nixosExtraAarch64;
in
nix-tests.runTests {
  "W04: aarch64 static wallpaper, skwdWall disabled" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is NOT enabled (skwdWall disabled)" =
      helpers.isFalse (H.skwdDeckEnabled config);
  };
}
