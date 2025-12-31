{
  pkgs,
  config,
  lib,
  vars,
  ...
}:
let
  # 1. PREPARE WALLPAPERS
  # Converts the list of wallpaper objects into a list of local file paths
  wallpaperFiles = builtins.map (
    wp:
    "${pkgs.fetchurl {
      url = wp.wallpaperURL;
      sha256 = wp.wallpaperSHA256;
    }}"
  ) vars.wallpapers;

  # 2. DETERMINE POLARITY
  # Helper to determine if we are in dark or light mode
  polarity = vars.polarity or "dark";

  # 3. HELPER FUNCTION
  # Capitalizes the first letter of a string (mocha -> Mocha)
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  # 4. CONSTRUCT THEME NAME
  # Builds the exact theme string required by KDE (e.g., "CatppuccinMochaSky")
  theme =
    if vars.catppuccin then
      "Catppuccin${capitalize vars.catppuccinFlavor}${capitalize vars.catppuccinAccent}"
    else if vars.polarity == "dark" then
      "BreezeDark"
    else
      "BreezeLight";

  # 5. LOOK AND FEEL
  lookAndFeel =
    if vars.polarity == "dark" then "org.kde.breezedark.desktop" else "org.kde.breeze.desktop";
  cursorTheme = config.stylix.cursor.name;
in
{

  config = lib.mkIf (vars.kde or false) {

    xdg.configFile."autostart/ibus-daemon.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=Kill IBus Daemon
      Exec=pkill ibus-daemon
      Hidden=false
      StartupNotify=false
      X-KDE-autostart-phase=1
    '';

    programs.plasma = {
      enable = true;

      # FORCE SETTINGS
      # Ensures these settings overwrite existing config files on every build
      overrideConfig = lib.mkForce true;

      workspace = {
        clickItemTo = "select"; # Require double-click to open files (Windows-style)

        colorScheme = theme;
        lookAndFeel = lookAndFeel;
        cursor.theme = cursorTheme;

        # Passes the list of wallpapers to Plasma Manager
        # It maps them to monitors sequentially (Monitor 1 -> Wallpaper 1, etc.)
        wallpaper = wallpaperFiles;
      };

      # 6. ADVANCED CONFIG (kdeglobals)
      # Direct edits to the KDE configuration database
      configFile = {
        "kdeglobals"."KDE"."widgetStyle" = if vars.catppuccin then "kvantum" else "Breeze";
        "kdeglobals"."General"."AccentColor" = if vars.catppuccin then "203,166,247" else null; # Manual mauve fallback
      };
    };

    # -----------------------------------------------------------------------
    # 📦 KDE PACKAGES
    # -----------------------------------------------------------------------
    # Apps installed only when KDE is the active desktop
    home.packages = with pkgs.kdePackages; [
      kcalc
      kcolorchooser
      elisa # Music Player
      okular # PDF Viewer
      konsole # Terminal

      # Theme dependencies
      pkgs.catppuccin-kde
      pkgs.catppuccin-kvantum
    ];
  };
}
