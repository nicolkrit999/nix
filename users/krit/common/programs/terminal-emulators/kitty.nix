{ delib
, lib
, config
, pkgs
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

  myconfig.ifEnabled = { myconfig, ... }: {
    stylix.targets.kitty.enable = !myconfig.constants.theme.catppuccin;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      isDarwin = moduleSystem == "darwin";
      cfg = myconfig.krit.programs.kitty;
      terminal = myconfig.constants.terminal;

      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      colors =
        if hasStylixPalette then config.lib.stylix.colors
        else {
          base00 = "1e1e2e";
          base0D = "89b4fa";
        };

      stylixKittyOn = myconfig.stylix.enable && (myconfig.stylix.targets.kitty.enable or true);
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      catppuccin.kitty.enable = myconfig.constants.theme.catppuccin;
      catppuccin.kitty.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.kitty = {
        enable = true;
        settings = {
          font_family = lib.mkIf (!stylixKittyOn) "JetBrainsMono Nerd Font";
          background_opacity = lib.mkForce "1.0";
          copy_on_select = "yes";
          window_padding_width = 4;
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          mouse_hide_wait = "3.0";

          cursor_shape = terminal.cursorStyle;
          cursor_blink_interval = if terminal.cursorBlink then "0.75 ease-in-out" else "0";
          cursor_beam_thickness = toString terminal.cursorBeamWidth;

          cursor_trail = 200; # Min stationary time in ms before trail triggers
          cursor_trail_decay = "0.15 0.4"; # Slow decay — trail lingers 150-400ms for visible effect
        }
        // lib.optionalAttrs (cfg.fontSize != null) {
          font_size = cfg.fontSize;
        }
        // lib.optionalAttrs isDarwin {
          macos_option_as_alt = "yes";
        };

        # Accent (base0D) cursor with the background colour (base00) under it. Must come
        # after the stylix theme include (order 1000), which sets both keys to base05.
        extraConfig = lib.mkAfter ''
          cursor #${colors.base0D}
          cursor_text_color #${colors.base00}
        '';
      };
    };
}
