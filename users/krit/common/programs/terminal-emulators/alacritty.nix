{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "krit.programs.alacritty";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.alacritty.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      terminal = myconfig.constants.terminal;

      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      colors =
        if hasStylixPalette then config.lib.stylix.colors
        else {
          base00 = "1e1e2e";
          base0D = "89b4fa";
        };
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.alacritty.enable = myconfig.constants.theme.catppuccin;
      catppuccin.alacritty.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.alacritty = {
        enable = true;
        settings = {
          window.opacity = lib.mkForce 1.0;
          font = {
            builtin_box_drawing = true;
            normal.family = lib.mkDefault "JetBrainsMono Nerd Font";
            normal.style = lib.mkForce "Bold";
          };

          cursor = {
            style = {
              shape =
                if terminal.cursorStyle == "block" then "Block"
                else if terminal.cursorStyle == "beam" then "Beam"
                else "Underline";
              blinking = if terminal.cursorBlink then "On" else "Off";
            };
            thickness = terminal.cursorBeamWidth / 12.0; # Convert pixels to cell fraction (~0.25 for 3px)
            vi_mode_style = {
              shape = "Block";
              blinking = "Off";
            };
          };
          colors.cursor = {
            cursor = lib.mkForce "#${colors.base0D}"; # Accent (base0D), distinct from text (base05) and background (base00)
            text = lib.mkForce "#${colors.base00}"; # Background color under cursor for contrast
          };
        };
      };
    };
}
