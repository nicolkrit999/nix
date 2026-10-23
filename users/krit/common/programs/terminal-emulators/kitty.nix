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

          # Guaranteed WCAG contrast (AA) between text and background: lifts only cells below the
          # ratio (e.g. Tokyo Night's dark-blue base03 used for bright-black/autosuggestions).
          minimum_contrast = "4.5";

          cursor_trail = 200; # Min stationary time in ms before trail triggers
          cursor_trail_decay = "0.15 0.4"; # Slow decay - trail lingers 150-400ms for visible effect
        }
        // lib.optionalAttrs isDarwin {
          macos_option_as_alt = "yes";
        };

        # Accent (base0D) cursor with the theme background under it. Must come after the stylix
        # theme include (order 1000), which sets the cursor keys to base05.
        extraConfig = lib.mkAfter ''
          cursor #${colors.base0D}
          cursor_text_color #${colors.base00}
        '';
      };
    };
}
