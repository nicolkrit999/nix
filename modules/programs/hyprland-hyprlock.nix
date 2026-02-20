{ delib, ... }:
delib.module {
  name = "programs.hyprlock";

  home.always =
    { lib, nixos, ... }:
    let
      # 🌟 EXACT ORIGINAL FALLBACK LOGIC
      hyprlandFallback =
        (nixos.programs.hyprland.enable or false)
        && !(nixos.programs.caelestia.enableOnHyprland or false)
        && !(nixos.programs.noctalia.enableOnHyprland or false);

      niriFallback =
        (nixos.programs.niri.enable or false) && !(nixos.programs.noctalia.enableOnNiri or false);
    in
    lib.mkIf (hyprlandFallback || niriFallback) {
      catppuccin.hyprlock.enable = nixos.constants.catppuccin;
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
