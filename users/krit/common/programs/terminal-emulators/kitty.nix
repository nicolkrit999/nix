{ delib
, lib
, pkgs
, config
, moduleSystem
, ...
}:
delib.module {
  name = "krit.programs.kitty";
  options = delib.singleEnableOption false;

  myconfig.ifEnabled.programs.kitty.enable = true;

  home.ifEnabled =
    { myconfig, ... }:
    let
      isDarwin = moduleSystem == "darwin";
      stylixKittyOn = myconfig.stylix.enable && (myconfig.stylix.targets.kitty.enable or true);

      hasStylixPalette = (builtins.tryEval config.lib.stylix.colors.base00).success;
      colors =
        if hasStylixPalette then config.lib.stylix.colors
        else {
          base00 = "1e1e2e";
          base0D = "89b4fa";
        };

      # Terminal background pushed away from the text colour (darker on dark schemes, lighter on
      # light ones) by a fixed fraction of the scheme's own base00, so any theme gets the same
      # relative contrast boost and keeps its hue. 0.20 equals Catppuccin Mantle on mocha.
      bgPush = 0.20;
      darkScheme = myconfig.constants.theme.polarity == "dark";
      pushBg = hex:
        let
          ch = i: lib.fromHexString (builtins.substring i 2 hex);
          shift = c: builtins.floor ((if darkScheme then c * (1.0 - bgPush) else c + (255 - c) * bgPush) + 0.5);
          h = n: lib.fixedWidthString 2 "0" (lib.toHexString n);
        in
        h (shift (ch 0)) + h (shift (ch 2)) + h (shift (ch 4));
      termBg = pushBg colors.base00;
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      programs.kitty = {
        settings = {
          font_family = lib.mkIf (!stylixKittyOn) "JetBrainsMono Nerd Font";
          background_opacity = lib.mkForce "1.0";
          copy_on_select = "yes";
          window_padding_width = 4;
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          mouse_hide_wait = "3.0";

          cursor_trail = 200; # Min stationary time in ms before trail triggers
          cursor_trail_decay = "0.15 0.4"; # Slow decay - trail lingers 150-400ms for visible effect
        }
        // lib.optionalAttrs isDarwin {
          macos_option_as_alt = "yes";
        };

        # Pushed background, plus an accent (base0D) cursor with that background under it. Must
        # come after the stylix theme include (order 1000), which sets the cursor keys to base05.
        extraConfig = lib.mkAfter ''
          background #${termBg}
          cursor #${colors.base0D}
          cursor_text_color #${termBg}
        '';
      };
    };
}
