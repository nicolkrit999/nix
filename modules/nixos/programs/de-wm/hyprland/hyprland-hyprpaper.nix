{ delib, pkgs, lib, ... }:
delib.module {
  name = "programs.hyprland";


  home.ifEnabled =
    { cfg, parent, myconfig, ... }:
    let
      wallpapersWithPaths = map
        (w: {
          monitor = if w.targetMonitor == "*" then "" else w.targetMonitor;
          path = pkgs.fetchurl { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; };
        })
        myconfig.constants.wallpapers;

      preloads = lib.unique (map (w: "${w.path}") wallpapersWithPaths);

      wallpaperSettings = map (w: "${w.monitor},${w.path}") wallpapersWithPaths;

      # Three-way active check: hyprpaper is the fallback only when no shell
      # is actually running on Hyprland (master + per-WM + wm.enable), not
      # just when the dormant per-WM preference is set.
      hyprlandEnabled = parent.hyprland.enable or false;
      caelestiaActiveOnHyprland =
        (parent.caelestia.enable or false)
        && (parent.caelestia.enableOnHyprland or false)
        && hyprlandEnabled;
      noctaliaActiveOnHyprland =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnHyprland or false)
        && hyprlandEnabled;

      hyprlandFallback =
        (cfg.enable or false)
        && !caelestiaActiveOnHyprland
        && !noctaliaActiveOnHyprland;

    in
    lib.mkIf hyprlandFallback {
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = preloads;
          wallpaper = wallpaperSettings;
        };
      };
    };
}
