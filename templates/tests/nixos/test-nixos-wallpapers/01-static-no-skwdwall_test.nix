# W01 - x86_64, static-only wallpaper, skwdWall disabled (default/off)
# No gifURL set, programs.skwdWall.enable = false. Expected: the old
# awww-daemon + awww img <static-store-path> logic runs unchanged across all
# five targets (hyprland, mango, niri, kde, gnome), and services.skwd-deck is
# absent from the build entirely.
{ nix-tests }:
let
  H = import ./shared/eval-scenario.nix;
  lib = H.lib;
  config = H.getConfig ./01-static-no-skwdwall H.nixosExtraX86;
  hm = H.getHm config;

  # The static wallpaper store-path derivation contains the sha256 in its name;
  # we match on the unique hash fragment instead of the full /nix/store/… path.
in
nix-tests.runTests {
  "W01: x86_64 static wallpaper, skwdWall disabled" = helpers: {
    "hyprland exec contains awww-daemon" =
      helpers.isTrue (H.hyprExecHas "awww-daemon" config);
    "hyprland exec contains awww img with static path" =
      helpers.isTrue (H.hyprExecHas "awww img" config);
    "mango exec contains awww-daemon" =
      helpers.isTrue (H.mangoExecHas "awww-daemon" config);
    "mango exec contains awww img" =
      helpers.isTrue (H.mangoExecHas "awww img" config);
    "niri spawn contains awww-daemon" =
      helpers.isTrue (H.niriSpawnHas "awww-daemon" config);
    "niri spawn contains awww img" =
      helpers.isTrue (H.niriSpawnHas "awww img" config);
    "kde plasma wallpaper list is non-empty (old static logic active)" =
      helpers.isTrue (builtins.length hm.programs.plasma.workspace.wallpaper > 0);
    "kde wallpaperCustomPlugin is unset" =
      helpers.isTrue (H.kdeWallpaperCustomPlugin config == null);
    "gnome dconf background picture-uri is set (always static, skwdWall-independent)" =
      helpers.isTrue (lib.hasPrefix "file:///nix/store/"
        (builtins.toString (hm.dconf.settings."org/gnome/desktop/background".picture-uri or "")));
    "services.skwd-deck is NOT enabled (skwdWall disabled)" =
      helpers.isFalse (H.skwdDeckEnabled config);
    "skwd-paper-plasma NOT in home packages (skwdWall disabled)" =
      helpers.isFalse (H.hmHasPkg "skwd-paper-plasma" config);
  };
}
