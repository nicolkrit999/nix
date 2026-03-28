{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      user = strOption "nixos";
      hostname = strOption "nixos-host";
      mainLocale = strOption "en_US.UTF-8";
      gitUserName = strOption "";
      gitUserEmail = strOption "";

      shell = strOption "bash";
      browser = strOption "chromium";
      editor = strOption "nano";
      fileManager = strOption "dolphin";


      wallpapers =
        listOfOption
          (submodule {
            options = {
              targetMonitor = strOption "*"; # Match any unassigned monitors
              wallpaperURL = strOption "";
              wallpaperSHA256 = strOption "";
            };
          })
          [
            {
              targetMonitor = "*"; # Fallback applied automatically to any unassigned monitors
              wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
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
        rounding = intOption 10;          # Corner radius in pixels (0 = sharp, 10 = refined rounded)
        gap = intOption 5;                # Inner gap between windows; outer gap is derived as 2× in hyprland-main
        borderSize = intOption 2;         # Border thickness in pixels (2 = visible but not distracting)
        terminalOpacity = floatOption 0.9; # Terminal background opacity (0.9 = subtle transparency)
      };

      niri = {
        gap      = intOption 8;  # Gap between windows and screen edges (single value; 8px = one grid unit, between Hyprland's gaps_in=5 and gaps_out=10)
        rounding = intOption 10; # Window corner radius in pixels — matches hyprland.rounding for visual coherence
      };

      terminal = {
        name = strOption "alacritty"; # Terminal emulator app name
        cursorStyle = strOption "block"; # block, beam, underline
        cursorBlink = boolOption true;     # Blinking cursor (true = better UX for locating cursor)
        cursorBeamWidth = floatOption 3.0; # Beam cursor width in pixels or cell fraction
        animation = boolOption true;  # Enable transient prompt animation on command execution
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
