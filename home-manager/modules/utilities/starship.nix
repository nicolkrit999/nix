{
  lib,
  config,
  vars,
  ...
}:
let

  # Get the Stylix Base16 Hex Color
  base16Accent = config.lib.stylix.colors.withHashtag.base0E;

  # Determine the "Main" color based on whatever catppuccin is enabled or not
  mainColor = if vars.catppuccin then vars.catppuccinAccent else base16Accent;

  # Status Colors (Dynamic)
  successColor = if vars.catppuccin then "green" else config.lib.stylix.colors.withHashtag.base0B;
  errorColor = if vars.catppuccin then "red" else config.lib.stylix.colors.withHashtag.base08;
in
{
  # -----------------------------------------------------------------------
  # 🎨 CATPPUCCIN THEME
  # -----------------------------------------------------------------------
  catppuccin.starship.enable = vars.catppuccin;
  catppuccin.starship.flavor = vars.catppuccinFlavor;

  # -----------------------------------------------------------------------
  # 🚀 STARSHIP CONFIGURATION
  # -----------------------------------------------------------------------
  programs.starship = {
    enable = true;
    # It fallback to true if not defined in the modules.nix of that specific host host
    # This allow user that have it enabled in their .zshrc_custom to not have issues
    enableZshIntegration = (vars.shell == "zsh") && (vars.starshipZshIntegration or true);

    enableFishIntegration = (vars.shell == "fish") && (vars.starshipFishIntegration or true);

    enableBashIntegration = (vars.shell == "bash") && (vars.starshipBashIntegration or true);

    settings = {
      add_newline = true;

      # -----------------------------------------------------
      # 👤 HOSTNAME
      # -----------------------------------------------------
      hostname = {
        ssh_only = false;
        format = "[$ssh_symbol$hostname]($style) ";
        # 🟢 RESULT: "bold mauve" OR "bold #bd93f9"
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
