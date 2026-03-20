{ delib
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "krit-kitty";
  options.krit.programs.kitty = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { myconfig, ... }:
    let
      isDarwin = moduleSystem == "darwin";
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
        }
        # macOS-specific settings
        // lib.optionalAttrs isDarwin {
          macos_option_as_alt = "yes";
        };
      };
    };
}
