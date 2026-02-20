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
      catppuccin.lazygit.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.lazygit.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.lazygit.accent = myconfig.constants.theme.catppuccinAccent or "mauve";
      # -----------------------------------------------------------------------
      programs.lazygit = {
        enable = true;

        settings = {
          gui.showIcons = true; # Enables Nerd Font icons to match your terminal style
        };
      };
    };
}
