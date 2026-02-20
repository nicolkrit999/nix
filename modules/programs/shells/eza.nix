{ delib, ... }:
delib.module {
  name = "programs.eza";
  options.programs.eza = with delib; {
    enable = boolOption false;
  };

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
      catppuccin.eza.enable = myconfig.constants.catppuccin or false;
      catppuccin.eza.flavor = myconfig.constants.catppuccinFlavor or "mocha";
      catppuccin.eza.accent = myconfig.constants.catppuccinAccent or "mauve";

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
