{ delib, ... }:
delib.module {
  name = "programs.lazygit";
  options.programs.lazygit = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { constants, ... }:
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # -----------------------------------------------------------------------
      catppuccin.lazygit.enable = constants.catppuccin or false;
      catppuccin.lazygit.flavor = constants.catppuccinFlavor or "mocha";
      catppuccin.lazygit.accent = constants.catppuccinAccent or "mauve";
      # -----------------------------------------------------------------------
      programs.lazygit = {
        enable = true;

        settings = {
          gui.showIcons = true; # Enables Nerd Font icons to match your terminal style
        };
      };
    };
}
