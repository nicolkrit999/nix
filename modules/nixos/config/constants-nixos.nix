{ delib, lib, ... }:
let
  # I-19: single source of the fallback wallpaper, reused by the wallpapers default and every consumer
  fallbackWallpaper = {
    url = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
    sha256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
  };
in
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      user = strOption "nixos";
      hostname = strOption "nixos-host";
      mainLocale = strOption "en_US.UTF-8";
      lcTime = strOption "";

      homeStateVersion = noDefault (strOption null);

      browser = strOption "chromium";
      fileManager = strOption "dolphin";

      # Apps that need to be launched inside a terminal (used by smartLaunch helpers)
      terminalApps = listOfOption lib.types.str [
        "nvim"
        "neovim"
        "vim"
        "nano"
        "hx"
        "helix"
        "yazi"
        "ranger"
        "lf"
        "nnn"
      ];


      fallbackWallpaperURL = strOption fallbackWallpaper.url;
      fallbackWallpaperSHA256 = strOption fallbackWallpaper.sha256;

      wallpapers =
        listOfOption
          (submodule {
            options = {
              targetMonitor = strOption "*"; # Match any unassigned monitors
              wallpaperURL = strOption "";
              wallpaperSHA256 = strOption "";
              gifURL = strOption "";
              gifSHA256 = strOption "";
              videoURL = strOption "";
              videoSHA256 = strOption "";
            };
          })
          [
            {
              targetMonitor = "*"; # Fallback applied automatically to any unassigned monitors
              wallpaperURL = fallbackWallpaper.url;
              wallpaperSHA256 = fallbackWallpaper.sha256;
            }
          ];

      primaryWallpaper = lib.mkOption {
        type = lib.types.attrs;
        readOnly = true;
        internal = true;
        description = "Derived: the '*' entry, else the first entry, else the fallback constant";
      };

      screenshotsAbs = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        internal = true;
        description = "Derived: screenshots with $HOME expanded to the absolute home path";
      };

      hyprland = {
        rounding = intOption 10;
        gap = intOption 5;
        borderSize = intOption 2;
        terminalOpacity = floatOption 1.0;
      };

      niri = {
        gap = intOption 8;
        rounding = intOption 10;
      };

      screenshots = strOption "$HOME/Pictures/Screenshots";
      keyboardLayout = strOption "us";
      keyboardVariant = strOption "";

      weather = strOption "London";
      useFahrenheit = boolOption false;
      timeZone = strOption "Etc/UTC";

      emergencyAccess = boolOption false;
    };
  myconfig.always =
    { cfg, ... }:
    let
      ws = cfg.wallpapers;
    in
    {
      constants.screenshotsAbs =
        builtins.replaceStrings [ "$HOME" ] [ "/home/${cfg.user}" ] cfg.screenshots;
      constants.primaryWallpaper =
        if ws == [ ] then
          {
            wallpaperURL = cfg.fallbackWallpaperURL;
            wallpaperSHA256 = cfg.fallbackWallpaperSHA256;
          }
        else
          lib.findFirst (w: w.targetMonitor == "*") (builtins.head ws) ws;
    };
}
