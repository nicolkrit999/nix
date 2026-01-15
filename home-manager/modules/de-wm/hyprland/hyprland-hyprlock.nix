{
  config,
  lib,
  vars,
  ...
}:
{
  config = lib.mkIf ((vars.hyprland or false) && !(vars.caelestia or false)) {
    # -----------------------------------------------------------------------
    # 🎨 CATPPUCCIN THEME (official module)
    catppuccin.hyprlock.enable = vars.catppuccin;
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

        background = lib.mkForce [
          {
            path = "screenshot"; # Takes a screenshot of your current desktop
            blur_passes = 3; # Heavily blurs it
            blur_size = 8; # Larger blur size for stronger effect
          }
        ];

      };
    };
  };
}
