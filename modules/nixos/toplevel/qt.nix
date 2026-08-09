{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "qt";

  # Stylix.targets.qt is intentionally NOT enabled - it forces
  # qt.platformTheme.name = "qtct" crashing plasma sessions

  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      hyprEnabled = myconfig.programs.hyprland.enable or false;
      kdeEnabled = myconfig.programs.kde.enable or false;
      useKdePlatformTheme = hyprEnabled || kdeEnabled;

      isDark = (myconfig.constants.theme.polarity or "dark") == "dark";
      iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";
    in
    {
      home.sessionVariables = {
        QT_QPA_PLATFORMTHEME = if useKdePlatformTheme then "kde" else "qt5ct";
      };

      home.packages =
        (with pkgs; [
          libsForQt5.qt5ct
          kdePackages.qt6ct
          papirus-icon-theme
          kdePackages.breeze
        ])
        ++ lib.optionals useKdePlatformTheme (
          with pkgs;
          [
            kdePackages.plasma-integration
            kdePackages.kconfig
          ]
        );

      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=Breeze
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt6ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=Breeze
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt5ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      xdg.dataFile."color-schemes/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."color-schemes/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
      xdg.dataFile."qt6ct/colors/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."qt6ct/colors/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
      xdg.dataFile."qt5ct/colors/BreezeDark.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
      xdg.dataFile."qt5ct/colors/BreezeLight.colors".source =
        "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
    };
}
