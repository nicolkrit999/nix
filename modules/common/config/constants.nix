{ delib, ... }:
delib.module {
  name = "constants";

  options =
    with delib;
    moduleOptions {
      gitUserName = strOption "";
      gitUserEmail = strOption "";

      shell = enumOption [ "bash" "fish" "zsh" ] "bash";
      editor = strOption "nano";

      terminal = {
        name = strOption "alacritty";
        cursorStyle = strOption "block"; # block, beam, underline
        cursorBlink = boolOption true; # Blinking cursor (true = better UX for locating cursor)
        cursorBeamWidth = floatOption 3.0; # Beam cursor width in pixels (converted per terminal)
        fontSize = floatOption 11.0; # Font size in pt, shared by kitty and alacritty (per-program fontSize overrides it)
        animation = boolOption true; # Enable transient prompt animation on command execution
      };

      theme = {
        polarity = strOption "dark";
        base16Theme = strOption "catppuccin-mocha";
        catppuccin = boolOption false;
        catppuccinFlavor = strOption "mocha";
        catppuccinAccent = strOption "mauve";
        # hyprlock sizes, applied only when catppuccin = true (defaults = the catppuccin theme's own values)
        lockAvatarSize = intOption 100; # Profile picture edge in px; its position shifts to keep the gap to the input field
        lockClockFontSize = intOption 90; # Time label font size; the date label moves to keep the gap below it
        lockDateFontSize = intOption 25;
        lockInputWidth = intOption 300;
        lockInputHeight = intOption 60;
      };

      nixImpure = boolOption false; # NixOS/Darwin rebuild aliases use nixos-rebuild/darwin-rebuild --impure instead of nh; home aliases append --impure (home-manager, nix flake check)

      flakeDir = strOption "nix"; # Flake checkout, relative to the user's home
    };
}
