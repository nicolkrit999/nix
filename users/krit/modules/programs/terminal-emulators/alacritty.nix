{
  delib,
  lib,
  ...
}:
delib.module {
  name = "krit.programs.alacritty";
  options.krit.programs.alacritty = with delib; {
    enable = boolOption false;
  };

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
        };
      };
    };
}
