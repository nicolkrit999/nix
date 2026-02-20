{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.gnome";
  # Define the toggle here
  options.programs.gnome = with delib; {
    enable = boolOption false;
    screenshots = strOption "$HOME/Pictures/Screenshots";
    pinnedApps = listOfOption str [ ];
    gnomeExtraBinds = listOfOption attrs [ ];
  };
  home.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:

    let
      firstWallpaper = builtins.head constants.wallpapers;
      wallpaperPath = pkgs.fetchurl {
        url = firstWallpaper.wallpaperURL;
        sha256 = firstWallpaper.wallpaperSHA256;
      };

      colorScheme = if constants.polarity == "dark" then "prefer-dark" else "prefer-light";
      iconThemeName = if constants.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";

      rawPinnedApps = cfg.pinnedApps;
      hasPins = builtins.length rawPinnedApps > 0;
    in
    {

      home.packages =
        (lib.optionals constants.catppuccin [
          (pkgs.catppuccin-gtk.override {
            accents = [ constants.catppuccinAccent ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = constants.catppuccinFlavor or "mocha";
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
