{ delib, lib, ... }:
delib.module {
  name = "programs.alacritty";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      fontSize = lib.mkOption {
        type = lib.types.nullOr lib.types.number;
        default = null;
        description = "Terminal font size; null uses constants.terminal.fontSize.";
      };
    };

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.alacritty.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      terminal = myconfig.constants.terminal;
    in
    {
      catppuccin.alacritty.enable = myconfig.constants.theme.catppuccin;
      catppuccin.alacritty.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.alacritty = {
        enable = true;
        settings = {
          cursor = {
            style = {
              shape =
                if terminal.cursorStyle == "block" then "Block"
                else if terminal.cursorStyle == "beam" then "Beam"
                else "Underline";
              blinking = if terminal.cursorBlink then "On" else "Off";
            };
            thickness = terminal.cursorBeamWidth / 12.0; # Convert pixels to cell fraction (~0.25 for 3px)
          };
          font.size = if cfg.fontSize != null then cfg.fontSize else terminal.fontSize;
        };
      };
    };
}
