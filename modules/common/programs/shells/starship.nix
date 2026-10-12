{ delib
, config
, ...
}:
delib.module {
  name = "programs.starship";
  options = delib.singleEnableOption true;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      isCatppuccin = myconfig.constants.theme.catppuccin;
      currentShell = myconfig.constants.shell;

      colors = config.lib.stylix.colors.withHashtag;

      mainColor = if isCatppuccin then myconfig.constants.theme.catppuccinAccent else colors.base0E;

      successColor = if isCatppuccin then "green" else colors.base0B;

      errorColor = if isCatppuccin then "red" else colors.base08;
    in
    {
      catppuccin.starship.enable = isCatppuccin;
      catppuccin.starship.flavor = myconfig.constants.theme.catppuccinFlavor;

      programs.starship = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";
        enableTransience = myconfig.constants.terminal.animation;

        settings = {
          add_newline = true;

          hostname = {
            ssh_only = false;
            format = "[$ssh_symbol$hostname]($style) ";
            style = "bold ${mainColor}";
          };

          username = {
            show_always = true;
            format = "[$user](bold ${mainColor})@";
          };

          character = {
            success_symbol = "[ & ](bold ${successColor})";
            error_symbol = "[ & ](bold ${errorColor})";
          };

          directory = {
            read_only = " 🔒";
            truncation_symbol = "…/";
          };

          aws.disabled = true;
          gcloud.disabled = true;
        };
      };
    };
}
