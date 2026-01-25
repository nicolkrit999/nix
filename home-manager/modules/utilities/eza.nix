{ vars, ... }:
let
  currentShell = vars.shell or "zsh";
in
{
  # ------------------------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME (official module)
  # ------------------------------------------------------------------------------------
  catppuccin.eza.enable = vars.catppuccin or false;
  catppuccin.eza.flavor = vars.catppuccinFlavor or "mocha";
  catppuccin.eza.accent = vars.catppuccinAccent or "mauve";

  # ------------------------------------------------------------------------------------
  programs.eza = {
    enable = true;
    enableZshIntegration = currentShell == "zsh";
    enableFishIntegration = currentShell == "fish";
    enableBashIntegration = currentShell == "bash";

    colors = "always";
    git = true;
    icons = "always";
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
