{ delib
, lib
, config
, ...
}:
delib.module {
  name = "krit.programs.alacritty";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    {
      catppuccin.alacritty.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.alacritty.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

      programs.alacritty = {
        enable = true;
        settings = {
          window.opacity = 1.0;
          font = {
            builtin_box_drawing = true;
            normal.style = lib.mkForce "Bold";
          };

          # Cursor styling from constants with base16 colors
          cursor = {
            style = {
              shape =
                let cursorStyle = myconfig.constants.terminal.cursorStyle or "block";
                in if cursorStyle == "block" then "Block"
                else if cursorStyle == "beam" then "Beam"
                else "Underline";
              blinking = if (myconfig.constants.terminal.cursorBlink or false) then "On" else "Off";
            };
            thickness = (myconfig.constants.terminal.cursorBeamWidth or 3.0) / 12.0; # Convert pixels to cell fraction (~0.25 for 3px)
            vi_mode_style = {
              shape = "Block";
              blinking = "Off";
            };
          };
          colors.cursor = {
            cursor = "#${config.lib.stylix.colors.base0D}"; # Accent blue (base0D) — distinct from text (base05) and background (base00)
            text = "#${config.lib.stylix.colors.base00}"; # Background color under cursor for contrast
          };
        };
      };
    } // lib.optionalAttrs (myconfig.stylix.enable or false) {
      stylix.targets.alacritty.enable = !(myconfig.constants.theme.catppuccin or false);
    };
}
