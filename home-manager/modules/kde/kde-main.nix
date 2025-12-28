{
  pkgs,
  lib,
  wallpapers,
  config,
  catppuccin,
  catppuccinFlavor,
  catppuccinAccent,
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
  ) wallpapers;

  # 2. DETERMINE POLARITY
  # Helper to determine if we are in dark or light mode
  polarity = config.stylix.polarity;

  # 3. HELPER FUNCTION
  # Capitalizes the first letter of a string (mocha -> Mocha)
  capitalize =
    s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

  # 4. CONSTRUCT THEME NAME
  # Builds the exact theme string required by KDE (e.g., "CatppuccinMochaSky")
  theme =
    if catppuccin then
      "Catppuccin${capitalize catppuccinFlavor}${capitalize catppuccinAccent}"
    else if polarity == "dark" then
      "BreezeDark"
    else
      "BreezeLight";

  # 5. LOOK AND FEEL
  lookAndFeel = if polarity == "dark" then "org.kde.breezedark.desktop" else "org.kde.breeze.desktop";

  cursorTheme = config.stylix.cursor.name;
in
{

  xdg.desktopEntries."ibus-wayland-custom" = {
    name = "IBus Wayland (Custom Fix)";
    comment = "Custom IBus launcher to fix env vars";
    exec = "sh -c \"env -u GTK_IM_MODULE -u QT_IM_MODULE ${pkgs.ibus}/libexec/ibus-ui-gtk3 --enable-wayland-im --exec-daemon --daemon-args '--xim --panel disable'\"";
    type = "Application";
    noDisplay = true;
  };

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
      "kdeglobals"."KDE"."widgetStyle" = if catppuccin then "kvantum" else "Breeze";
      "kdeglobals"."General"."AccentColor" = if catppuccin then "203,166,247" else null; # Manual mauve fallback

      # Tells KDE to officially use IBus as the Virtual Keyboard/Input Method
      "kwinrc"."Wayland"."InputMethod" = "ibus-wayland-custom.desktop";
      "kwinrc"."Wayland"."VirtualKeyboardEnabled" = true;
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
    gwenview # Image Viewer
    okular # PDF Viewer
    konsole # Terminal

    # Theme dependencies
    pkgs.catppuccin-kde
    pkgs.catppuccin-kvantum
  ];
}
