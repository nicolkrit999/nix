{ delib, ... }:
delib.module {
  name = "programs.lazygit";
  options.programs.lazygit = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    { nixos, ... }:
    {
      # -----------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # -----------------------------------------------------------------------
      catppuccin.lazygit.enable = nixos.constants.catppuccin or false;
      catppuccin.lazygit.flavor = nixos.constants.catppuccinFlavor or "mocha";
      catppuccin.lazygit.accent = nixos.constants.catppuccinAccent or "mauve";
      # -----------------------------------------------------------------------
      programs.lazygit = {
        enable = true;

        settings = {
          gui.showIcons = true; # Enables Nerd Font icons to match your terminal style
        };
      };
    };
}
