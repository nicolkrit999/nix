{ delib, lib, ... }:
delib.module {
  name = "services.hyprlock";
  options.services.hyprlock = with delib; {
    enable = boolOption true;
    settings = attrsOption { };
  };

  home.always =
    { myconfig, ... }:
    let
      hyprlandFallback =
        (myconfig.programs.hyprland.enable or false)
        && !(myconfig.programs.caelestia.enableOnHyprland or false)
        && !(myconfig.programs.noctalia.enableOnHyprland or false);
      niriFallback =
        (myconfig.programs.niri.enable or false) && !(myconfig.programs.noctalia.enableOnNiri or false);

    in
    lib.mkIf (hyprlandFallback || niriFallback) {

      catppuccin.hyprlock.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.hyprlock.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";
      catppuccin.hyprlock.accent = myconfig.constants.theme.catppuccinAccent or "mauve";

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
