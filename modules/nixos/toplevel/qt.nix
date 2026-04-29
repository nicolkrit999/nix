{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "qt";

  # Qt/KDE color theming (kdeglobals palette + colorscheme files) is delegated
  # to stylix.targets.kde — it follows polarity + base16Theme, writes into
  # xdg.systemDirs.config (immune to plasma-manager overrideConfig), and
  # supplies the colorscheme via XDG_DATA_DIRS for any DE/WM.
  #
  # This module owns the *non-color* Qt plumbing only:
  #   - QPA platform theme env var
  #   - qt5ct/qt6ct config (used outside KDE)
  #   - icon theme
  #
  # NOTE: stylix.targets.qt is intentionally NOT enabled — it forces
  # qt.platformTheme.name = "qtct", which strips plasma-integration from
  # Plasma's own Qt widgets and crashes Plasma sessions. kde target alone is
  # safe; qt target is not.
  #
  # Pre-stylix-delegation implementation preserved in `qt-old.nix.bak`.

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
      # Outside a Plasma session, "kde" platform theme still works as long as
      # plasma-integration is installed; falls back to qt5ct elsewhere.
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
            libsForQt5.kconfig
          ]
        );

      # qt5ct/qt6ct configuration for non-KDE Qt apps. Color palette comes from
      # the BreezeDark/Light .colors file referenced below — stylix doesn't
      # write qt5ct configs because stylix.targets.qt is disabled.
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
