{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  hyprEnabled = vars.hyprland or false;
  kdeEnabled = vars.kde or false;
  useKdePlatformTheme = hyprEnabled || kdeEnabled;
  isDark = (vars.polarity or "dark") == "dark";
  kdeColorScheme = if isDark then "BreezeDark" else "BreezeLight";
  iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";
in
{
  home.packages =
    (with pkgs; [
      libsForQt5.qt5ct
      kdePackages.qt6ct

      papirus-icon-theme
    ])
    ++ (with pkgs; [ kdePackages.breeze ])
    ++ lib.optionals useKdePlatformTheme (
      with pkgs;
      [
        kdePackages.plasma-integration

        kdePackages.kconfig
        libsForQt5.kconfig
      ]
    );

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

  xdg.configFile."qt6ct/qt6ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt6ct/colors/${kdeColorScheme}.colors
  '';

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    icon_theme=${iconThemeName}
    style=breeze
    color_scheme_path=${config.home.homeDirectory}/.local/share/qt5ct/colors/${kdeColorScheme}.colors
  '';

  home.activation.kdeglobalsFromPolarity = lib.mkIf useKdePlatformTheme (
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons      --key Theme      "${iconThemeName}"  || true

      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
      ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group Icons      --key Theme      "${iconThemeName}"  || true
    ''
  );
}
