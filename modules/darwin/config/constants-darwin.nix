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

      terminal = {
        name = strOption "alacritty"; # Terminal emulator app name
        cursorStyle = strOption "block"; # block, beam, underline
        cursorBlink = boolOption false;
        animation = boolOption false; # Enable transient prompt animation on command execution
      };
      shell = strOption "bash";
      browser = strOption "firefox";
      editor = strOption "nano";
      fileManager = strOption "nnn";



      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "catppuccin-mocha";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "mocha";
        catppuccinAccent = strOption "mauve";
      };


      nixImpure = boolOption false;

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
