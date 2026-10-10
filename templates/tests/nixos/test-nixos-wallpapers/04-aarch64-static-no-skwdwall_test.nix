# W04 - aarch64-linux, static-only wallpaper, skwdWall disabled
# Mirror of W01 on aarch64. Expected: same supervisor + awww-daemon behaviour as
# x86_64 for every WM, and services.skwd-deck absent from the build.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  E = H.expect;
  config = H.getConfig ./04-aarch64-static-no-skwdwall H.nixosExtraAarch64;
in
nix-tests.runTests {
  "W04: aarch64 static wallpaper, skwdWall disabled" = helpers:
    H.perWm helpers config [
      E.supervisor
      E.daemon
      (E.spec "*=image:" "*=image:")
      E.noDirectAwww
    ]
    // {
      "services.skwd-deck is NOT enabled (skwdWall disabled)" =
        helpers.isFalse (H.skwdDeckEnabled config);
    };
}
