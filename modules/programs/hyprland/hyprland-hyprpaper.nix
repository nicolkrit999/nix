{
  delib,
  pkgs,
  lib,
  myconfig,
  ...
}:
delib.module {
  name = "programs.hyprpaper"; # Assuming you register it directly

  home.always =
    let
      activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) myconfig.constants.monitors;
      monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;
      images = map (
        w:
        pkgs.fetchurl {
          url = w.wallpaperURL;
          sha256 = w.wallpaperSHA256;
        }
      ) myconfig.constants.wallpapers;
      getWallpaper =
        index: if index < builtins.length images then builtins.elemAt images index else lib.last images;

      # 🌟 EXACT ORIGINAL CONDITION
      hyprlandFallback =
        (myconfig.programs.hyprland.enable or false)
        && !(myconfig.programs.caelestia.enableOnHyprland or false)
        && !(myconfig.programs.noctalia.enableOnHyprland or false);
    in
    lib.mkIf hyprlandFallback {
      services.hyprpaper = {
        enable = true;
        settings = {
          preload = map (i: "${i}") images;
          wallpaper = lib.imap0 (i: port: "${port}, ${getWallpaper i}") monitorPorts;
        };
      };
    };
}
