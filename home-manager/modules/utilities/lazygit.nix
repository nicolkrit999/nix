{ vars, ... }: {
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME (official module)
  # -----------------------------------------------------------------------
  catppuccin.lazygit.enable = vars.catppuccin or false;
  catppuccin.lazygit.flavor = vars.catppuccinFlavor or "mocha";
  catppuccin.lazygit.accent = vars.catppuccinAccent or "mauve";
  # -----------------------------------------------------------------------
  programs.lazygit = {
    enable = true;

    settings = {
      gui.showIcons =
        true; # Enables Nerd Font icons to match your terminal style
    };
  };
}
