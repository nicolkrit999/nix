{ vars, ... }:
{
  # ------------------------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME (official module)
  # a stylix.nix 'enable = false;' is not required since eza uses its own theming system
  # ------------------------------------------------------------------------------------
  catppuccin.eza.enable = vars.catppuccin;
  catppuccin.eza.flavor = vars.catppuccinFlavor;
  catppuccin.eza.accent = vars.catppuccinAccent;
  # ------------------------------------------------------------------------------------
  programs.eza = {
    enable = true;
    enableZshIntegration = vars.shell == "zsh";
    enableFishIntegration = vars.shell == "fish";
    enableBashIntegration = vars.shell == "bash";
    colors = "always";

    git = true;
    icons = "always";

    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
