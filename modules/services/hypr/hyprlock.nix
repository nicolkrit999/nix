{ delib, lib, ... }:
delib.module {
  name = "services.hyprlock";
  options.services.hyprlock = with delib; {
    enable = boolOption true;
    settings = attrsOption { };
  };

  nixos.always =
    { cfg, myconfig, ... }:
    let
      # 🌟 EXACT ORIGINAL FALLBACK LOGIC
      hyprlandFallback =
        (myconfig.contants.programs.hyprland.enable or false)
        && !(myconfig.contants.programs.caelestia.enableOnHyprland or false)
        && !(myconfig.contants.programs.noctalia.enableOnHyprland or false);

      niriFallback =
        (myconfig.contants.programs.niri.enable or false)
        && !(myconfig.contants.programs.noctalia.enableOnNiri or false);
    in
    lib.mkIf (hyprlandFallback || niriFallback) {
      catppuccin.hyprlock.enable = myconfig.contants.catppuccin;
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
