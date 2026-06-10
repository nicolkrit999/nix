# W07 — noctalia active on hyprland, waypaper enabled
# noctalia.enableOnHyprland = true → hyprland wallpaper owned by shell.
# noctalia.enableOnNiri = false, enableOnMango = false → niri + mango see waypaper.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./07-noctalia-hyprland-waypaper H.nixosExtraX86;
in
nix-tests.runTests {
  "W07: noctalia on hyprland + waypaper enabled" = helpers: {
    # Hyprland: shell owns wallpaper — neither awww nor waypaper
    "hyprland exec does NOT contain awww-daemon (shell owns wallpaper)" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "hyprland exec does NOT contain waypaper --restore (shell owns wallpaper)" =
      helpers.isFalse (H.hyprExecHas "waypaper --restore" config);
    # Mango: no shell active, waypaper enabled → waypaper --restore
    "mango exec contains waypaper --restore (waypaper active, no shell on mango)" =
      helpers.isTrue (H.mangoExecHas "waypaper --restore" config);
    "mango exec does NOT contain awww-daemon" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    # Niri: no shell active, waypaper enabled → waypaper --restore
    "niri spawn contains waypaper --restore (waypaper active, no shell on niri)" =
      helpers.isTrue (H.niriSpawnHas "waypaper --restore" config);
    "niri spawn does NOT contain awww-daemon" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    # waypaper package present (module enabled)
    "waypaper IS in home packages" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
  };
}
