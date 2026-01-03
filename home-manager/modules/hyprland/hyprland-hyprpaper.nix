{
  pkgs,
  lib,
  vars,
  ...
}:
let

  # Do not apply wallpapers to disabled monitors
  activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) vars.monitors;
  monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;

  images = map (
    w:
    pkgs.fetchurl {
      url = w.wallpaperURL;
      sha256 = w.wallpaperSHA256;
    }
  ) vars.wallpapers;

  getWallpaper =
    index: if index < builtins.length images then builtins.elemAt images index else lib.last images;

in
{

  config = lib.mkIf ((vars.hyprland or false) && !(vars.caelestia or false)) {
    services.hyprpaper = {
      enable = true;
      settings = {
        preload = map (i: "${i}") images;
        wallpaper = lib.imap0 (i: port: "${port}, ${getWallpaper i}") monitorPorts;
      };
    };
  };
}
