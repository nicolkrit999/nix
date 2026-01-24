{ pkgs, vars, ... }: {
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME (official module)
  # -----------------------------------------------------------------------
  catppuccin.bat.enable = vars.catppuccin or false;
  catppuccin.bat.flavor = vars.catppuccinFlavor or "mocha";
  # -----------------------------------------------------------------------

  programs.bat = {
    enable = true;

    config = {
      # Optional: any other bat config options (like --style)
    };
  };
}
