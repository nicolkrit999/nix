# W06 — aarch64-linux, static wallpaper, waypaper ENABLED
# Key difference from W03: linux-wallpaperengine must NOT be in packages (arch guard).
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./06-aarch64-waypaper H.nixosExtraAarch64;
in
nix-tests.runTests {
  "W06: aarch64 static wallpaper, waypaper enabled" = helpers: {
    "hyprland exec contains waypaper --restore" =
      helpers.isTrue (H.hyprExecHas "waypaper --restore" config);
    "hyprland exec does NOT contain awww-daemon" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "mango exec contains waypaper --restore" =
      helpers.isTrue (H.mangoExecHas "waypaper --restore" config);
    "niri spawn contains waypaper --restore" =
      helpers.isTrue (H.niriSpawnHas "waypaper --restore" config);
    "waypaper IS in home packages" =
      helpers.isTrue (H.hmHasPkg "waypaper" config);
    "linux-wallpaperengine NOT in home packages (aarch64 arch guard)" =
      helpers.isFalse (H.hmHasPkg "linux-wallpaperengine" config);
  };
}
