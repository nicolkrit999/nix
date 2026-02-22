{
  delib,
  pkgs,
  lib,
  inputs,
  ...
}:
delib.module {
  name = "qt";

  options.qt = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    {
      myconfig,
      ...
    }:
    let
      # Determine which environments are active
      hyprEnabled = myconfig.programs.hyprland.enable or false;
      kdeEnabled = myconfig.programs.kde.enable or false;
      useKdePlatformTheme = hyprEnabled || kdeEnabled;

      # Theme Variables
      isDark = (myconfig.constants.theme.polarity or "dark") == "dark";
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
      flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      capitalize =
        s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

      # Dynamically calculate the precise color scheme name
      kdeColorScheme =
        if isCatppuccin then
          "Catppuccin${capitalize flavor}${capitalize accent}"
        else if isDark then
          "BreezeDark"
        else
          "BreezeLight";

      iconThemeName = if isDark then "Papirus-Dark" else "Papirus-Light";

      # Use kvantum engine for Catppuccin, otherwise stick to standard Breeze
      widgetStyle = if isCatppuccin then "kvantum" else "Breeze";
    in
    {
      # Ensures WMs like Niri and Cosmic correctly theme Qt apps even without KDE running
      home.sessionVariables = {
        QT_QPA_PLATFORMTHEME = if useKdePlatformTheme then "kde" else "qt5ct";
      };

      home.packages =
        (with pkgs; [
          libsForQt5.qt5ct
          kdePackages.qt6ct
          papirus-icon-theme
        ])
        ++ (with pkgs; [ kdePackages.breeze ])
        # Ensure Catppuccin assets exist even if KDE is completely disabled in flake.nix
        ++ lib.optionals isCatppuccin (
          with pkgs;
          [
            catppuccin-kde
            catppuccin-kvantum
          ]
        )
        ++ lib.optionals useKdePlatformTheme (
          with pkgs;
          [
            kdePackages.plasma-integration
            kdePackages.kconfig
            libsForQt5.kconfig
          ]
        );

      # QT5CT / QT6CT CONFIGURATION (Used by Niri, Cosmic, Gnome)
      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=${widgetStyle}
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt6ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=${widgetStyle}
        color_scheme_path=/home/${myconfig.constants.user}/.local/share/qt5ct/colors/${
          if isDark then "BreezeDark" else "BreezeLight"
        }.colors
      '';

      # Symlink the standard Breeze colors so Qt5ct/Qt6ct can find them
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

      xdg.configFile."Kvantum/kvantum.kvconfig" = lib.mkIf isCatppuccin {
        text = ''
          [General]
          theme=catppuccin-${flavor}-${accent}
        '';
      };

      # KDEGLOBALS ACTIVATION SCRIPT (Used by Hyprland and KDE)
      # Forcefully aligns the KDE engine with our calculated values on every rebuild
      home.activation.kdeglobalsFromPolarity = lib.mkIf useKdePlatformTheme (
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group Icons      --key Theme       "${iconThemeName}"  || true
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group KDE        --key widgetStyle "${widgetStyle}"    || true

          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group General    --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group UiSettings --key ColorScheme "${kdeColorScheme}" || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group Icons      --key Theme       "${iconThemeName}"  || true
          ${pkgs.libsForQt5.kconfig}/bin/kwriteconfig5 --file kdeglobals --group KDE        --key widgetStyle "${widgetStyle}"    || true
        ''
      );
    };
}
