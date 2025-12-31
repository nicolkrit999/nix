{
  pkgs,
  lib,
  config,
  vars,
  ...
}:

# This file is delicate, if modified without care it can break both Catppuccin and Stylix themes.
let
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  kvantumTheme =
    if vars.catppuccin then
      "Catppuccin-${capitalize vars.catppuccinFlavor}-${capitalize vars.catppuccinAccent}"
    else if vars.polarity == "dark" then
      "KvGnomeDark"
    else
      "KvFlatLight";

  iconThemeName = if vars.polarity == "dark" then "Papirus-Dark" else "Papirus-Light";
in
{
  config = lib.mkMerge [
    {
      home.sessionVariables = {
        QT_QPA_PLATFORM = "wayland;xcb";
        QT_QUICK_CONTROLS_STYLE = "org.kde.desktop";
        # Do not set QT_QPA_PLATFORMTHEME globally here, otherwise kde plasma crash
      };

      # Install necessary packages for both modes
      home.packages =
        with pkgs;
        [
          libsForQt5.qt5ct
          kdePackages.qt6ct
          libsForQt5.qtstyleplugin-kvantum # Contains the 'kvantummanager' executable
          kdePackages.qtstyleplugin-kvantum
          pkgs.papirus-icon-theme
        ]
        ++ (lib.optionals vars.catppuccin [
          pkgs.catppuccin-kvantum
        ]);
    }

    # --- CONFIG FILES (Apply to BOTH Catppuccin and Stylix modes) ---
    {
      # 1. Kvantum Config (The Theme Engine)
      xdg.configFile."Kvantum/kvantum.kvconfig".text = ''
        [General]
        theme=${kvantumTheme}
      '';

      # 2. QtCT Configs (The Bridge)
      xdg.configFile."qt6ct/qt6ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';

      xdg.configFile."qt5ct/qt5ct.conf".text = ''
        [Appearance]
        icon_theme=${iconThemeName}
        style=kvantum
      '';
    }

    # --- CATPPUCCIN SPECIFIC (Only copy theme files if needed) ---
    (lib.mkIf vars.catppuccin {
      xdg.configFile."Kvantum/${kvantumTheme}".source =
        "${pkgs.catppuccin-kvantum}/share/Kvantum/${kvantumTheme}";
    })
  ];
}
