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
      hyprEnabled = myconfig.programs.hyprland.enable;
      kdeEnabled = myconfig.programs.kde.enable;
      useKdePlatformTheme = hyprEnabled || kdeEnabled;

      isDark = myconfig.constants.theme.polarity == "dark";
      iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";
      schemeName = if isDark then "BreezeDark" else "BreezeLight";
      dataHome = "/home/${myconfig.constants.user}/.local/share";
      breezeSchemes = "${pkgs.kdePackages.breeze}/share/color-schemes";
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

      xdg = {
        configFile."qt6ct/qt6ct.conf".text = ''
          [Appearance]
          icon_theme=${iconThemeName}
          style=Breeze
          color_scheme_path=${dataHome}/qt6ct/colors/${schemeName}.colors
        '';

        configFile."qt5ct/qt5ct.conf".text = ''
          [Appearance]
          icon_theme=${iconThemeName}
          style=Breeze
          color_scheme_path=${dataHome}/qt5ct/colors/${schemeName}.colors
        '';

        dataFile = {
          "color-schemes/BreezeDark.colors".source = "${breezeSchemes}/BreezeDark.colors";
          "color-schemes/BreezeLight.colors".source = "${breezeSchemes}/BreezeLight.colors";
          "qt6ct/colors/BreezeDark.colors".source = "${breezeSchemes}/BreezeDark.colors";
          "qt6ct/colors/BreezeLight.colors".source = "${breezeSchemes}/BreezeLight.colors";
          "qt5ct/colors/BreezeDark.colors".source = "${breezeSchemes}/BreezeDark.colors";
          "qt5ct/colors/BreezeLight.colors".source = "${breezeSchemes}/BreezeLight.colors";
        };
      };
    };
}
