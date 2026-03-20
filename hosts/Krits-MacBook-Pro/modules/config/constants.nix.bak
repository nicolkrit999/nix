{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      user = strOption "krit";
      hostname = strOption "Krits-MacBook-Pro";
      uid = intOption 501;

      terminal = strOption "kitty";
      shell = strOption "fish";
      browser = strOption "firefox";
      editor = strOption "nvim";
      fileManager = strOption "yazi";

      darwinStateVersion = intOption 4;
      homeStateVersion = strOption "25.11";

      gitUserName = strOption "";
      gitUserEmail = strOption "";

      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "nord";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "macchiato";
        catppuccinAccent = strOption "mauve";
      };
    };

  myconfig.always =
    { cfg, ... }:
    {
      args.shared.constants = cfg;
    };
}
