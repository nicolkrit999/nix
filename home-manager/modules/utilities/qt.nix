{ pkgs, lib, config, vars, ... }: {
  # -----------------------------------------------------------------------
  # 🎨 QT THEMING (Managed by Stylix)
  # -----------------------------------------------------------------------
  # Since 'stylix.targets.qt.enable = true' in stylix.nix,
  # Stylix will automatically:
  # 1. Set QT_QPA_PLATFORMTHEME="qt5ct" (or qt6ct)
  # 2. Generate the qt5ct.conf and qt6ct.conf files using the Base16 theme.
  # -----------------------------------------------------------------------

  home.packages = with pkgs; [
    # Tools required by Stylix to apply the theme
    libsForQt5.qt5ct
    kdePackages.qt6ct

    # The Breeze style engine (needed for the widget shapes)
    kdePackages.breeze

    # Icons
    pkgs.papirus-icon-theme
  ];

  # Force Wayland for Qt apps (if not already set globally in hyprland/env)
  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
  };
}
