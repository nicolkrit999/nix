{ delib, ... }:
delib.module {
  name = "programs.hyprlock";

  home.always =
    { lib, myconfig, ... }:
    let
      # 🌟 EXACT ORIGINAL FALLBACK LOGIC
      hyprlandFallback =
        (myconfig.programs.hyprland.enable or false)
        && !(myconfig.programs.caelestia.enableOnHyprland or false)
        && !(myconfig.programs.noctalia.enableOnHyprland or false);

      niriFallback =
        (myconfig.programs.niri.enable or false) && !(myconfig.programs.noctalia.enableOnNiri or false);
    in
    lib.mkIf (hyprlandFallback || niriFallback) {
      catppuccin.hyprlock.enable = myconfig.constants.catppuccin;
      programs.hyprlock = {
        enable = true;
        settings = {
          general = {
            disable_loading_bar = true;
            grace = 10;
            hide_cursor = true;
            no_fade_in = false;
          };
          background = lib.mkForce [
            {
              path = "screenshot";
              blur_passes = 3;
              blur_size = 8;
            }
          ];
        };
      };
    };
}
