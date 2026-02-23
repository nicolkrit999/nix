{ delib
, lib
, ...
}:
delib.module {
  name = "krit-kitty";
  options.krit.programs.kitty = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { myconfig, ... }:
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
          confirm_os_window_close = 0;
          enable_audio_bell = false;
          mouse_hide_wait = "3.0";
        };
      };
    };
}
