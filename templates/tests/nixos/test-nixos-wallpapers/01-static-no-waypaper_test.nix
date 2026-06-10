# W01 — x86_64, static-only wallpaper, waypaper disabled
# No gifURL set. Expected: awww-daemon + awww img <static-store-path> in all
# three WM exec lists. waypaper --restore must NOT appear. linux-wallpaperengine
# must NOT be in home packages (waypaper module disabled).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./01-static-no-waypaper H.nixosExtraX86;

  # The static wallpaper store-path derivation contains the sha256 in its name;
  # we match on the unique hash fragment instead of the full /nix/store/… path.
in
nix-tests.runTests {
  "W01: x86_64 static wallpaper, no waypaper" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img with static path" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "hyprland exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec contains awww img" =
      helpers.isTrue (H.mangoExecHas "awww img" config);
    "mango exec does NOT contain waypaper --restore" =
      helpers.isFalse (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn contains awww img" =
      helpers.isTrue (H.niriSpawnHas "awww img" config);
    "niri spawn does NOT contain waypaper --restore" =
      helpers.isFalse (H.niriSpawnHas "waypaper --restore" config);
    "linux-wallpaperengine NOT in home packages (waypaper disabled)" =
      helpers.isFalse (H.hmHasPkg "linux-wallpaperengine" config);
    "waypaper NOT in home packages (waypaper disabled)" =
      helpers.isFalse (H.hmHasPkg "waypaper" config);
  };
}
