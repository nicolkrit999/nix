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
          let
            useFallback = w.wallpaperURL == "";
          in
          "${pkgs.fetchurl {
          url = if useFallback then myconfig.constants.fallbackWallpaperURL else w.wallpaperURL;
          sha256 = if useFallback then myconfig.constants.fallbackWallpaperSHA256 else w.wallpaperSHA256;
        }}"
        )
        myconfig.constants.wallpapers;

      isCatppuccin = myconfig.constants.theme.catppuccin;
      flavor = myconfig.constants.theme.catppuccinFlavor;
      accent = myconfig.constants.theme.catppuccinAccent;
      # mirrors the stylix KDE target default in stylix-nixos.nix (on unless catppuccin)
      stylixKde = myconfig.stylix.enable && (myconfig.stylix.targets.kde.enable or (!isCatppuccin));

      colorScheme =
        if stylixKde then
          null
        else if isCatppuccin then
          "Catppuccin${lib.toSentenceCase flavor}${lib.toSentenceCase accent}"
        else if myconfig.constants.theme.polarity == "dark" then
          "BreezeDark"
        else
          "BreezeLight";

      lookAndFeel =
        if stylixKde then
          null
        else if myconfig.constants.theme.polarity == "dark" then
          "org.kde.breezedark.desktop"
        else
          "org.kde.breeze.desktop";

      cursorTheme = lib.mkIf (config.stylix.cursor != null) config.stylix.cursor.name;
    in
    {
      # Kills the system-wide ibus autostart in Plasma; under its own name so it does not
      # shadow /etc/xdg/autostart/ibus-daemon.desktop. Memory: project_ibus_kill_workaround.md
      xdg.configFile."autostart/kde-ibus-kill.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Kill IBus Daemon
        Exec=sh -c "pkill ibus-daemon || true"
        Hidden=false
        StartupNotify=false
        OnlyShowIn=KDE;
        X-KDE-autostart-phase=1
      '';

      # plasma-manager's workspace.wallpaper can't select a non-org.kde.image plugin, so
      # wallpaperCustomPlugin is used instead when skwd-wall owns the wallpaper.
      home.packages =
        lib.optional skwdWallPlasmaAvailable inputs.skwd-wall.packages.${pkgs.stdenv.hostPlatform.system}.skwd-paper-plasma
        ++ lib.optional isCatppuccin (pkgs.catppuccin-kde.override {
          flavour = [ flavor ];
          accents = [ accent ];
        });

      programs.plasma = {
        enable = true;
        overrideConfig = true;

        workspace = {
          clickItemTo = "select";

          inherit colorScheme lookAndFeel;
          cursor.theme = cursorTheme;
          wallpaper = lib.mkIf (!skwdWallPlasmaAvailable) wallpaperPaths;
          wallpaperCustomPlugin = lib.mkIf skwdWallPlasmaAvailable {
            plugin = "org.skwd.wall.plasma";
          };
        };
      };

    };
}
