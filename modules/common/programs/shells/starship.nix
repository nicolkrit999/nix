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
      isCatppuccin = myconfig.constants.theme.catppuccin or false;
      currentShell = myconfig.constants.shell or "zsh";

      base16Accent = config.lib.stylix.colors.withHashtag.base0E;

      mainColor =
        if isCatppuccin then (myconfig.constants.theme.catppuccinAccent or "mauve") else base16Accent;

      successColor = if isCatppuccin then "green" else config.lib.stylix.colors.withHashtag.base0B;

      errorColor = if isCatppuccin then "red" else config.lib.stylix.colors.withHashtag.base08;
    in
    {
      # -----------------------------------------------------------------------
      catppuccin.starship.enable = isCatppuccin;
      catppuccin.starship.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

      programs.starship = {
        enable = true;
        enableZshIntegration = currentShell == "zsh";
        enableFishIntegration = currentShell == "fish";
        enableBashIntegration = currentShell == "bash";

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
