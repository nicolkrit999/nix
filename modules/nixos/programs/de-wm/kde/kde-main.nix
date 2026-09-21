{ delib
, pkgs
, lib
, config
, inputs
, moduleSystem
, ...
}:
delib.module {
  name = "programs.kde";

  options =
    with delib;
    moduleOptions {
      extraBinds = attrsOption { };
      mice = listOfOption attrs [ ];
      touchpads = listOfOption attrs [ ];
      pinnedApps = listOfOption str [ ];
    };

  nixos.always = { ... }: {
    home-manager.sharedModules = [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.plasma-manager.homeModules.plasma-manager
    ];
  };

  home.ifEnabled =
    { myconfig
    , parent
    , ...
    }:
    let
      skwdWallActive = parent.skwdWall.enable or false;

      # skwd-wall only publishes x86_64-linux outputs; guard the attr access so
      # aarch64-linux hosts don't hit a missing-attribute eval error.
      skwdWallPlasmaAvailable = skwdWallActive && pkgs.stdenv.hostPlatform.isx86_64;

      wallpaperPaths = builtins.map
        (
          w:
          "${pkgs.fetchurl {
          url = w.wallpaperURL;
          sha256 = w.wallpaperSHA256;
        }}"
        )
        myconfig.constants.wallpapers;

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

      # skwd-wall's Plasma wallpaper plugin (x86_64-linux only, matches this
      # file's nixos-only placement). plasma-manager's workspace.wallpaper
      # can't select a non-org.kde.image plugin, so wallpaperCustomPlugin is
      # used instead when skwd-wall owns the wallpaper.
      home.packages = lib.optional skwdWallPlasmaAvailable inputs.skwd-wall.packages.${pkgs.system}.skwd-paper-plasma;

      programs.plasma = {
        enable = true;
        overrideConfig = lib.mkForce true;

        workspace = {
          clickItemTo = "select";

          colorScheme = theme;
          lookAndFeel = lookAndFeel;
          cursor.theme = cursorTheme;
          wallpaper = lib.mkIf (!skwdWallPlasmaAvailable) wallpaperPaths;
          wallpaperCustomPlugin = lib.mkIf skwdWallPlasmaAvailable {
            plugin = "org.skwd.wall.plasma";
          };
        };
      };

    };
}
