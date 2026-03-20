{ delib, ... }:
delib.module {
  name = "programs.eza";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig, ... }:
    {
      catppuccin.eza.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.eza.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.eza.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

      programs.eza = {
        enable = true;
        enableZshIntegration = (myconfig.constants.shell or "zsh") == "zsh";
        enableFishIntegration = (myconfig.constants.shell or "zsh") == "fish";
        enableBashIntegration = (myconfig.constants.shell or "zsh") == "bash";
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
