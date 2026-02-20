{ delib, lib, ... }:
delib.module {
  name = "services.hyprlock";
  options.services.hyprlock = with delib; {
    enable = boolOption true;
    settings = attrsOption { };
  };

  nixos.always =
    { constants, ... }:
    let
      # 🌟 EXACT ORIGINAL FALLBACK LOGIC
      hyprlandFallback =
        (constants.programs.hyprland.enable or false)
        && !(constants.programs.caelestia.enableOnHyprland or false)
        && !(constants.programs.noctalia.enableOnHyprland or false);

      niriFallback =
        (constants.programs.niri.enable or false) && !(constants.programs.noctalia.enableOnNiri or false);
    in
    lib.mkIf (hyprlandFallback || niriFallback) {
      catppuccin.hyprlock.enable = constants.catppuccin;
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
