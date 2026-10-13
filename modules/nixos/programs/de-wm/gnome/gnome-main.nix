{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.gnome";
  options =
    with delib;
    moduleOptions {
      pinnedApps = listOfOption str [ ];
      extraBinds = listOfOption attrs [ ];
    };

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      primaryWp = myconfig.constants.primaryWallpaper;
      useFallbackWp = primaryWp.wallpaperURL == "";
      wallpaperPath = pkgs.fetchurl {
        url = if useFallbackWp then myconfig.constants.fallbackWallpaperURL else primaryWp.wallpaperURL;
        sha256 = if useFallbackWp then myconfig.constants.fallbackWallpaperSHA256 else primaryWp.wallpaperSHA256;
      };
      colorScheme = if myconfig.constants.theme.polarity == "dark" then "prefer-dark" else "prefer-light";
      iconThemeName =
        if myconfig.constants.theme.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
    in
    {
      home.packages =
        (lib.optionals myconfig.constants.theme.catppuccin [
          (pkgs.catppuccin-gtk.override {
            accents = [ myconfig.constants.theme.catppuccinAccent ];
            size = "standard";
            tweaks = [
              "rimless"
              "black"
            ];
            variant = myconfig.constants.theme.catppuccinFlavor;
          })
        ])
        ++ [
          pkgs.hydrapaper
          pkgs.papirus-icon-theme
        ];

      dconf.settings = {
        "org/gnome/desktop/interface" = {
          color-scheme = lib.mkForce colorScheme;
          icon-theme = iconThemeName;
        };

        "org/gnome/desktop/background" = {
          picture-uri = lib.mkForce "file://${wallpaperPath}";
          picture-uri-dark = lib.mkForce "file://${wallpaperPath}";
          picture-options = lib.mkForce "zoom";
        };

        "org/gnome/desktop/screensaver" = {
          picture-uri = lib.mkForce "file://${wallpaperPath}";
        };

        "org/gnome/desktop/wm/preferences" = {
          button-layout = "appmenu:minimize,maximize,close";
        };

        "org/gnome/shell" = lib.mkIf (cfg.pinnedApps != [ ]) { favorite-apps = cfg.pinnedApps; };
      };
    };
}
