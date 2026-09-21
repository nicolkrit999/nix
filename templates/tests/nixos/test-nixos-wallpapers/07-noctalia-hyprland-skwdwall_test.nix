# W07 - noctalia active on hyprland, skwdWall ENABLED
# noctalia.enableOnHyprland = true → hyprland wallpaper owned by the shell
# either way. skwdWall.enable = true zeroes out mango/niri's awww exec too
# (skwdWallActive short-circuits the `!wallpaperOwnedByShell && !skwdWallActive`
# guard regardless of shell state), and services.skwd-deck runs system-wide.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./07-noctalia-hyprland-skwdwall H.nixosExtraX86;
in
nix-tests.runTests {
  "W07: noctalia on hyprland + skwdWall enabled" = helpers: {
    # Hyprland: shell owns wallpaper AND skwdWall is active - no awww either way
    "hyprland exec does NOT contain awww-daemon (shell + skwdWall both suppress it)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    # Mango: no shell active, but skwdWall enabled → still no awww
    "mango exec does NOT contain awww-daemon (skwdWall active, no shell on mango)" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    # Niri: no shell active, but skwdWall enabled → still no awww
    "niri spawn does NOT contain awww-daemon (skwdWall active, no shell on niri)" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
  };
}
