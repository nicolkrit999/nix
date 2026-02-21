{ delib, ... }:
delib.module {
  name = "constants";

  options.constants = with delib; {
    user = strOption "nixos";
    hostname = strOption "nixos-host";
    gitUserName = strOption "";
    gitUserEmail = strOption "";

    terminal = strOption "alacritty";
    shell = strOption "bash";
    browser = strOption "chromium";
    editor = strOption "nano";
    fileManager = strOption "nnn";

    monitors = listOfOption str [ ];

    # modules/config/constants.nix
    wallpapers =
      listOfOption
        (submodule {
          options = {
            wallpaperURL = strOption "";
            wallpaperSHA256 = strOption "";
          };
        })
        [
          # 🌟 THIS IS THE FALLBACK!
          # If default.nix provides no wallpapers, it will use this Nix Catppuccin one.
          {
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

    screenshots = strOption "$HOME/Pictures/Screenshots";
    keyboardLayout = strOption "us";
    keyboardVariant = strOption "";

    weather = strOption "London";
    useFahrenheit = boolOption false;
    nixImpure = boolOption false;
    timeZone = strOption "Etc/UTC";
  };

  myconfig.always =
    { cfg, ... }:
    {
      args.shared.constants = cfg;
    };
}
