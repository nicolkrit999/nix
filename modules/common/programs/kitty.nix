{ delib
, lib
, ...
}:
delib.module {
  name = "programs.kitty";
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
    stylix.targets.kitty.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    let
      terminal = myconfig.constants.terminal;
    in
    {
      catppuccin.kitty.enable = myconfig.constants.theme.catppuccin;
      catppuccin.kitty.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.kitty = {
        enable = true;
        settings = {
          cursor_shape = terminal.cursorStyle;
          cursor_blink_interval = if terminal.cursorBlink then "0.75 ease-in-out" else "0";
          cursor_beam_thickness = toString terminal.cursorBeamWidth;
        }
        // {
          font_size = if cfg.fontSize != null then cfg.fontSize else terminal.fontSize;
        };
      };
    };
}
