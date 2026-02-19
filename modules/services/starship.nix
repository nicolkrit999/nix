{
  lib,
  config,
  vars,
  ...
}:
let
  # 🛡️ SAFE FALLBACKS
  isCatppuccin = vars.catppuccin or false;
  currentShell = vars.shell or "zsh";

  base16Accent = config.lib.stylix.colors.withHashtag.base0E;

  mainColor = if isCatppuccin then (vars.catppuccinAccent or "mauve") else base16Accent;

  successColor = if isCatppuccin then "green" else config.lib.stylix.colors.withHashtag.base0B;

  errorColor = if isCatppuccin then "red" else config.lib.stylix.colors.withHashtag.base08;
in
{
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -----------------------------------------------------------------------
  catppuccin.starship.enable = isCatppuccin;
  catppuccin.starship.flavor = vars.catppuccinFlavor or "mocha";

  # -----------------------------------------------------------------------
  # 🚀 STARSHIP CONFIGURATION
  # -----------------------------------------------------------------------
  programs.starship = {
    enable = true;
    enableZshIntegration = currentShell == "zsh";
    enableFishIntegration = currentShell == "fish";
    enableBashIntegration = currentShell == "bash";

    settings = {
      add_newline = true;

      # -----------------------------------------------------
      # 👤 HOSTNAME
      # -----------------------------------------------------
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol$hostname]($style) ";
        style = "bold ${mainColor}";
      };

      # -----------------------------------------------------
      # 👤 USER
      # -----------------------------------------------------
      username = {
        show_always = true;
        format = "[$user](bold ${mainColor})@";
      };

      # -----------------------------------------------------
      # ⚡ COMMAND SYMBOLS
      # -----------------------------------------------------
      character = {
        success_symbol = "[ & ](bold ${successColor})";
        error_symbol = "[ & ](bold ${errorColor})";
      };

      # -----------------------------------------------------
      # 📁 DIRECTORY
      # -----------------------------------------------------
      directory = {
        read_only = " 🔒";
        truncation_symbol = "…/";
      };

      aws.disabled = true;
      gcloud.disabled = true;
    };
  };
}
