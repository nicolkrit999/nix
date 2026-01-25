{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  firstWallpaper = builtins.head vars.wallpapers;
  wallpaperPath = pkgs.fetchurl {
    url = firstWallpaper.wallpaperURL;
    sha256 = firstWallpaper.wallpaperSHA256;
  };

  colorScheme = if vars.polarity == "dark" then "prefer-dark" else "prefer-light";
  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";

  rawPinnedApps = vars.pinnedApps or [ ];
  hasPins = builtins.length rawPinnedApps > 0;
in
{
  config = lib.mkIf (vars.gnome or false) {

    home.packages =
      (lib.optionals vars.catppuccin [
        (pkgs.catppuccin-gtk.override {
          accents = [ vars.catppuccinAccent ];
          size = "standard";
          tweaks = [
            "rimless"
            "black"
          ];
          variant = vars.catppuccinFlavor or "mocha";
        })
      ])
      ++ [
        pkgs.papirus-icon-theme
        pkgs.hydrapaper
      ];

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = lib.mkForce colorScheme;
        icon-theme = iconThemeName;
      };

      "org/gnome/desktop/background" = {
        picture-uri = "file://${wallpaperPath}";
        picture-uri-dark = "file://${wallpaperPath}";
        picture-options = lib.mkForce "zoom";
      };

      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://${wallpaperPath}";
      };

      "org/gnome/desktop/wm/preferences" = {
        button-layout = "appmenu:minimize,maximize,close";
      };

      "org/gnome/shell" = lib.mkIf hasPins { favorite-apps = rawPinnedApps; };
    };
  };
}
