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
    { cfg, nixos, ... }:

    let
      firstWallpaper = builtins.head nixos.constants.wallpapers;
      wallpaperPath = pkgs.fetchurl {
        url = firstWallpaper.wallpaperURL;
        sha256 = firstWallpaper.wallpaperSHA256;
      };

      colorScheme = if nixos.constants.polarity == "dark" then "prefer-dark" else "prefer-light";
      iconThemeName = if nixos.constants.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";

      rawPinnedApps = cfg.pinnedApps;
      hasPins = builtins.length rawPinnedApps > 0;
    in
    {

      home.packages =
        (lib.optionals nixos.constants.catppuccin [
          (pkgs.catppuccin-gtk.override {
            accents = [ nixos.constants.catppuccinAccent ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = nixos.constants.catppuccinFlavor or "mocha";
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
