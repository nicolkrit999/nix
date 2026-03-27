{ delib
, lib
, config
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.kitty";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      fontSize = lib.mkOption {
        type = lib.types.nullOr lib.types.number;
        default = null;
      };
    };

  home.ifEnabled =
    { myconfig, ... }:
    let
      isDarwin = moduleSystem == "darwin";
      cfg = myconfig.krit.programs.kitty;
    in
    {
      catppuccin.kitty.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.kitty.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

      programs.kitty = {
        enable = true;
        settings = {
          font_family = "JetBrainsMono Nerd Font";
          background_opacity = lib.mkForce "1.0";
          copy_on_select = "yes";
          window_padding_width = 4;
          confirm_os_window_close = if isDarwin then 0 else -1; # 0 = don't ask on macOS, -1 = never ask on NixOS
          enable_audio_bell = false;
          mouse_hide_wait = "3.0";
          shell_integration = "enabled";

          # Cursor styling from constants with base16 colors for contrast
          cursor_shape = myconfig.constants.terminal.cursorStyle or "block";
          cursor_blink_interval = if (myconfig.constants.terminal.cursorBlink or false) then "0.5" else "0";
          cursor = "#${config.lib.stylix.colors.base05}"; # Foreground color (base05)
          cursor_text_color = "#${config.lib.stylix.colors.base00}"; # Background color (base00)
          cursor_beam_thickness = toString (myconfig.constants.terminal.cursorBeamWidth or 3.0); # Wide beam cursor (default is 1.5)

          # Cursor trail animation - shows movement path when cursor jumps
          cursor_trail = 3; # Trail duration in number of cells (higher = longer trail)
          cursor_trail_decay = "0.1 0.4"; # Fade timing: start slow, end faster
          cursor_trail_start_threshold = 2; # Minimum distance to trigger trail
        }
        // lib.optionalAttrs (cfg.fontSize != null) {
          font_size = cfg.fontSize;
        }
        # macOS-specific settings
        // lib.optionalAttrs isDarwin {
          macos_option_as_alt = "yes";
        };
      };
    };
}
