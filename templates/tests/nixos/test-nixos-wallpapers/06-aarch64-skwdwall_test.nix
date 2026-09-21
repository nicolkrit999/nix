# W06 - aarch64-linux, static wallpaper, skwdWall ENABLED
# Same toggle as W03 but on aarch64-linux. The skwd-wall flake only publishes
# packages for x86_64-linux (see nix/binary-packages.nix upstream), so KDE's
# `inputs.skwd-wall.packages.${pkgs.system}.skwd-paper-plasma` lookup in
# kde-main.nix is guarded by `pkgs.stdenv.hostPlatform.isx86_64`
# (skwdWallPlasmaAvailable), so aarch64 simply omits the package instead of
# failing to evaluate. This test is the regression guard for that: if the
# arch guard is ever dropped, the hmHasPkg check below surfaces a real eval
# error - do NOT weaken it to hide that; route any failure to nix-debugger.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  config = H.getConfig ./06-aarch64-skwdwall H.nixosExtraAarch64;
  hm = H.getHm config;
in
nix-tests.runTests {
  "W06: aarch64 static wallpaper, skwdWall enabled" = helpers: {
    "hyprland exec does NOT contain awww-daemon" =
      helpers.isFalse (H.hyprExecHas "awww-daemon" config);
    "mango exec does NOT contain awww-daemon" =
      helpers.isFalse (H.mangoExecHas "awww-daemon" config);
    "niri spawn does NOT contain awww-daemon" =
      helpers.isFalse (H.niriSpawnHas "awww-daemon" config);
    "services.skwd-deck is enabled" =
      helpers.isTrue (H.skwdDeckEnabled config);
    "skwd-paper-plasma is NOT in home packages (aarch64 has no skwd-wall package)" =
      helpers.isFalse (H.hmHasPkg "skwd-paper-plasma" config);
    # aarch64 fallback: with no skwd plugin package available, KDE must not be
    # left with an empty wallpaper config - it falls back to the static list.
    "kde wallpaperCustomPlugin is unset (plugin package unavailable on aarch64)" =
      helpers.isTrue (H.kdeWallpaperCustomPlugin config == null);
    "kde plasma wallpaper list is non-empty (static fallback, not an empty config)" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
  };
}
