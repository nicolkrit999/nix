{ pkgs, lib, config, vars, ... }:
let
  colorScheme = if vars.polarity == "dark" then "BreezeDark" else "BreezeLight";

  iconThemeName =
    if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in {

  # 1. PACKAGES
  home.packages = with pkgs; [
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.breeze
    pkgs.papirus-icon-theme
  ];

  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
  };

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt6ct/colors/${colorScheme}.colors
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt5ct/colors/${colorScheme}.colors
  '';

  xdg.dataFile."qt6ct/colors/BreezeDark.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
  xdg.dataFile."qt6ct/colors/BreezeLight.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";

  xdg.dataFile."qt5ct/colors/BreezeDark.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
  xdg.dataFile."qt5ct/colors/BreezeLight.colors".source =
    "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeLight.colors";
}
