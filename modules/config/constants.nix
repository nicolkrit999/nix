{ delib, ... }:
delib.module {
  name = "constants";

  options.constants = with delib; {
    # ---------------------------------------------------------------
    # 👤 USER IDENTITY
    # ---------------------------------------------------------------
    username = strOption "nixos";
    gitUserName = strOption "";
    gitUserEmail = strOption "";

    # ---------------------------------------------------------------
    # 🐚 SHELLS & APPS
    # ---------------------------------------------------------------
    terminal = strOption "alacritty";
    shell = strOption "bash";
    browser = strOption "chromium";
    editor = strOption "nano";
    fileManager = strOption "nnn";

    # ---------------------------------------------------------------
    # ⚙️ ADVANCED SYSTEM CONSTANTS
    # ---------------------------------------------------------------
    zramPercent = intOption 25;
    snapshotRetention = {
      hourly = strOption "24";
      daily = strOption "7";
      weekly = strOption "4";
      monthly = strOption "3";
      yearly = strOption "2";
    };

    # ---------------------------------------------------------------
    # 🖼️ MONITORS & WALLPAPERS
    # ---------------------------------------------------------------
    monitors = listOfOption str [ ];

    # Using a submodule to strictly define the wallpaper attribute set
    wallpapers = listOfOption (submodule {
      options = {
        wallpaperURL = strOption "";
        wallpaperSHA256 = strOption "";
      };
    }) [ ];

    # ---------------------------------------------------------------
    # 🎨 THEMING
    # ---------------------------------------------------------------
    theme = {
      polarity = strOption "dark";
      base16Theme = strOption "catppuccin-mocha";
      catppuccin = boolOption false;
      catppuccinFlavor = strOption "mocha";
      catppuccinAccent = strOption "mauve";
    };

    screenshots = strOption "$HOME/Pictures/Screenshots";
    keyboardLayout = strOption "us";
    keyboardVariant = strOption "";
    pinnedApps = listOfOption str [ ];

    # 🌟 RESTORED FROM VARIABLES.NIX.BAK
    weather = strOption "Lugano";
    useFahrenheit = boolOption false;
    nixImpure = boolOption false;
    customGitIgnores = listOfOption str [ ];

    cachix = {
      enable = boolOption false;
      push = boolOption false;
      name = strOption "";
      publicKey = strOption "";
    };

    timeZone = strOption "Etc/UTC";
  };
}
