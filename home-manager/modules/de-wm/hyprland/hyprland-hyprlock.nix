{ config, lib, vars, ... }:
let
  # 1. Hyprland needs Hyprlock if it is enabled but has NO custom shell
  hyprlandFallback = (vars.hyprland or false)
    && !((vars.hyprlandCaelestia or false) || (vars.hyprlandNoctalia or false));

  # 2. Niri needs Hyprlock if it is enabled but has NO custom shell
  niriFallback = (vars.niri or false) && !(vars.niriNoctalia or false);

in {
  config = lib.mkIf (hyprlandFallback || niriFallback) {
    # -----------------------------------------------------------------------
    # 🎨 CATPPUCCIN THEME (official module)
    catppuccin.hyprlock.enable = vars.catppuccin or false;
    # -----------------------------------------------------------------------
    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          disable_loading_bar = true;
          grace = 10; # 10 seconds to unlock without password after locking
          hide_cursor = true;
          no_fade_in = false;
        };

        background = lib.mkForce [{
          path = "screenshot"; # Takes a screenshot of your current desktop
          blur_passes = 3; # Heavily blurs it
          blur_size = 8; # Larger blur size for stronger effect
        }];

      };
    };
  };
}
