{ delib, ... }:
delib.module {
  name = "programs.lazygit";
  options.programs.lazygit = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { cfg, myconfig, ... }:
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # -----------------------------------------------------------------------
      catppuccin.lazygit.enable = myconfig.constants.catppuccin or false;
      catppuccin.lazygit.flavor = myconfig.constants.catppuccinFlavor or "mocha";
      catppuccin.lazygit.accent = myconfig.constants.catppuccinAccent or "mauve";
      # -----------------------------------------------------------------------
      programs.lazygit = {
        enable = true;

        settings = {
          gui.showIcons = true; # Enables Nerd Font icons to match your terminal style
        };
      };
    };
}
