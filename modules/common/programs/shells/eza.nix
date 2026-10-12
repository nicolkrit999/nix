{ delib, ... }:
delib.module {
  name = "programs.eza";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      currentShell = myconfig.constants.shell;
    in
    {
      catppuccin.eza = {
        enable = myconfig.constants.theme.catppuccin;
        flavor = myconfig.constants.theme.catppuccinFlavor;
        accent = myconfig.constants.theme.catppuccinAccent;
      };

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
