{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {
      gitUserName = strOption "";
      gitUserEmail = strOption "";

      shell = strOption "bash";
      editor = strOption "nano";

      terminal = {
        name = strOption "alacritty";
        cursorStyle = strOption "block"; # block, beam, underline
        cursorBlink = boolOption true; # Blinking cursor (true = better UX for locating cursor)
        cursorBeamWidth = floatOption 3.0; # Beam cursor width in pixels (converted per terminal)
        animation = boolOption true; # Enable transient prompt animation on command execution
      };

      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "catppuccin-mocha";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "mocha";
        catppuccinAccent = strOption "mauve";
      };

      nixImpure = boolOption false;

      flakeDir = strOption "nix"; # Flake checkout, relative to the user's home
    };
}
