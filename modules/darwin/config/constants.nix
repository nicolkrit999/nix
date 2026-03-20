{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {

      hostname = strOption "nixdarwin-host";
      user = strOption "nixdarwin";
      uid = intOption 1000;
      gitUserName = strOption "";
      gitUserEmail = strOption "";

      # State versions
      darwinStateVersion = intOption 4;
      homeStateVersion = strOption "25.11";

      terminal = strOption "alacritty";
      shell = strOption "bash";
      browser = strOption "chromium";
      editor = strOption "nano";
      fileManager = strOption "dolphin";



      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "catppuccin-mocha";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "mocha";
        catppuccinAccent = strOption "mauve";
      };


      nixImpure = boolOption false;

      /*
      cachix = {
        enable = boolOption false;
        push = boolOption false;
        name = strOption "krit-nixos"; # Allow general users to use my custom cachix cache. Change if needed
        publicKey = strOption "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks="; # Public key of the krit cachix cache, change as needd
      };
      */
    };

  myconfig.always =
    { cfg, ... }:
    {
      args.shared.constants = cfg;
    };
}
