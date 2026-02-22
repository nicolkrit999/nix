{ delib, ... }:
delib.module {
  name = "programs.eza";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      currentShell = myconfig.constants.shell or "zsh";
    in
    {
      # ------------------------------------------------------------------------------------
      # 🎨 CATPPUCCIN THEME (official module)
      # ------------------------------------------------------------------------------------
      catppuccin.eza.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.eza.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.eza.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

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
    };
}
