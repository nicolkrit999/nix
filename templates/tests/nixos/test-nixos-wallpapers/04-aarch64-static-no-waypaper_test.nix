# W04 — aarch64-linux, static-only wallpaper, waypaper disabled
# Mirror of W01 on aarch64. Expected: same awww behavior as x86_64 for WMs.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./04-aarch64-static-no-waypaper H.nixosExtraAarch64;
in
nix-tests.runTests {
  "W04: aarch64 static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn does NOT contain waypaper --restore" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
    "waypaper NOT in home packages (waypaper disabled)" =
      helpers.isFalse (H.hmHasPkg "waypaper" config);
  };
}
