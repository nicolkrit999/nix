{
  pkgs,
  catppuccin,
  catppuccinFlavor,
  ...
}:
{

  # ------------------------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # ------------------------------------------------------------------------------------
  catppuccin.cava.enable = catppuccin;
  catppuccin.cava.flavor = catppuccinFlavor;

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
