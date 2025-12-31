{
  pkgs,
  vars,
  ...
}:
{

  # ------------------------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # ------------------------------------------------------------------------------------
  catppuccin.cava.enable = vars.catppuccin;
  catppuccin.cava.flavor = vars.catppuccinFlavor;

  programs.cava = {
    enable = true;

    settings = {
      general = {
        framerate = 60;
      };

      color = {
        gradient = 1;
        gradient_count = 8;
      };
    };
  };
}
