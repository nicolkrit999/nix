{ delib, lib, ... }:
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


      wallpapers =
        listOfOption
          (submodule {
            options = {
              targetMonitor = strOption "*"; # Match any unassigned monitors
              wallpaperURL = strOption "";
              wallpaperSHA256 = strOption "";
              gifURL = strOption "";
              gifSHA256 = strOption "";
            };
          })
          [
            {
              targetMonitor = "*"; # Fallback applied automatically to any unassigned monitors
              wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
              wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
            }
          ];

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
}
