{ delib
, pkgs
, lib
, config
, ...
}:
delib.module {
  name = "programs.kde";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      extraBinds = attrsOption { };
      mice = listOfOption attrs [ ];
      touchpads = listOfOption attrs [ ];
      pinnedApps = listOfOption str [ ];
    };

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
      wallpaperPath = "${pkgs.fetchurl { url = fallbackWp.wallpaperURL; sha256 = fallbackWp.wallpaperSHA256; }}";


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
          wallpaper = wallpaperPath;
        };
      };

    };
}
