{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.hyprpaper"; # Assuming you register it directly

  home.always =
    { constants, ... }:
    let
      activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) constants.monitors;
      monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;
      images = map (
        w:
        pkgs.fetchurl {
          url = w.wallpaperURL;
          sha256 = w.wallpaperSHA256;
        }
      ) constants.wallpapers;
      getWallpaper =
        index: if index < builtins.length images then builtins.elemAt images index else lib.last images;

      # 🌟 EXACT ORIGINAL CONDITION
      hyprlandFallback =
        (constants.programs.hyprland.enable or false)
        && !(constants.programs.caelestia.enableOnHyprland or false)
        && !(constants.programs.noctalia.enableOnHyprland or false);
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
