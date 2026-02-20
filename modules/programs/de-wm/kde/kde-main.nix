{
  delib,
  inputs,
  pkgs,
  lib,
  config,
  ...
}:
delib.module {
  name = "programs.kde";

  options.programs.kde = with delib; {
    enable = boolOption false;
    extraBinds = attrsOption { };
    mice = listOfOption attrs [ ];
    touchpads = listOfOption attrs [ ];
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      config,
      ...
    }:
    let
      wallpaperFiles = builtins.map (
        wp:
        "${pkgs.fetchurl {
          url = wp.wallpaperURL;
          sha256 = wp.wallpaperSHA256;
        }}"
      ) myconfig.constants.wallpapers;

      polarity = myconfig.constants.theme.polarity or "dark";

      capitalize =
        s: lib.toUpper (builtins.substring 0 1 s) + builtins.substring 1 (builtins.stringLength s) s;

      theme =
        if myconfig.constants.theme.catppuccin then
          "Catppuccin${capitalize myconfig.constants.theme.catppuccinFlavor}${capitalize myconfig.constants.theme.catppuccinAccent}"
        else if myconfig.constants.theme.polarity == "dark" then
          "BreezeDark"
        else
          "BreezeLight";

      lookAndFeel =
        if myconfig.constants.theme.polarity == "dark" then
          "org.kde.breezedark.desktop"
        else
          "org.kde.breeze.desktop";
      cursorTheme = config.stylix.cursor.name;
    in
    {

      #imports = [ inputs.plasma-manager.homeManagerModules.plasma-manager ];

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
        overrideConfig = lib.mkForce true;

        workspace = {
          clickItemTo = "select"; # Require double-click to open files (Windows-style)

          colorScheme = theme;
          lookAndFeel = lookAndFeel;
          cursor.theme = cursorTheme;
          wallpaper = wallpaperFiles;
        };
        configFile = {
          "kdeglobals"."KDE"."widgetStyle" =
            if myconfig.constants.theme.catppuccin then "kvantum" else "Breeze";
          "kdeglobals"."General"."AccentColor" =
            if myconfig.constants.theme.catppuccin then "203,166,247" else null;
        };
      };

      home.packages = with pkgs; [
        catppuccin-kde
        catppuccin-kvantum
      ];
    };
}
