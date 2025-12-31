{
  vars,
  ...
}:
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

    # --- Integration ---
    # Injects eza as the default listing command inside your Zsh environment.
    enableZshIntegration = true;

    # --- Display Options ---
    # ensures colored output and Nerd Font icons are always visible.
    colors = "always";

    # enables Git status indicators (showing if files are staged/modified).
    git = true;
    icons = "always";

    # --- Extra Parameters ---
    # groups folders at the top and adds headers to long listings.
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };
}
