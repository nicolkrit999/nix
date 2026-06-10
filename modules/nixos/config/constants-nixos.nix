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
      gitUserName = strOption "";
      gitUserEmail = strOption "";

      shell = strOption "bash";
      browser = strOption "chromium";
      editor = strOption "nano";
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
              # wallpaperURL must always be a valid static image path — it is consumed by
              # DEs, stylix, hyprlock, and kscreenlocker even when gifURL is set.
              wallpaperURL = strOption "";
              wallpaperSHA256 = strOption "";
              gifURL = strOption ""; # if non-empty, WMs use this GIF via awww; must be empty-string when unused
              gifSHA256 = strOption ""; # sha256 for gifURL; ignored when gifURL = ""
            };
          })
          [
            {
              targetMonitor = "*"; # Fallback applied automatically to any unassigned monitors
              wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
              wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
            }
          ];

      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "catppuccin-mocha";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "mocha";
        catppuccinAccent = strOption "mauve";
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

      terminal = {
        name = strOption "alacritty"; # Terminal emulator app name
        cursorStyle = strOption "block"; # block, beam, underline
        cursorBlink = boolOption true; # Blinking cursor (true = better UX for locating cursor)
        cursorBeamWidth = floatOption 3.0; # Beam cursor width in pixels or cell fraction
        animation = boolOption true; # Enable transient prompt animation on command execution
      };

      screenshots = strOption "$HOME/Pictures/Screenshots";
      keyboardLayout = strOption "us";
      keyboardVariant = strOption "";

      weather = strOption "London";
      useFahrenheit = boolOption false;
      nixImpure = boolOption false;
      timeZone = strOption "Etc/UTC";

      cachix = {
        enable = boolOption false;
        push = boolOption false;
        name = strOption "krit-nixos"; # Allow general users to use my custom cachix cache. Change if needed
        publicKey = strOption "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks="; # Public key of the krit cachix cache, change as needd
      };
    };

  myconfig.always =
    { cfg, ... }:
    {
      args.shared.constants = cfg;
    };
}
