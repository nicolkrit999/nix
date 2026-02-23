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

      hyprlandFallback =
        (cfg.enable or false)
        && !(parent.caelestia.enableOnHyprland or false)
        && !(parent.noctalia.enableOnHyprland or false);

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
