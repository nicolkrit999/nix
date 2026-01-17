{
  pkgs,
  lib,
  config,
  vars,
  ...
}:
let
  # Your custom layout tweaks (Fonts, Size, Rounding)
  customLayout = ''
    /* Force Font Family */
    * { font-family: "JetBrains Mono"; }

    /* 1. NOTIFICATION POPUP */
    .notification-row .notification-background { min-width: 30em; }

    /* 2. CONTROL CENTER (Sidebar) */
    .control-center { min-width: 15%; }

    /* 3. TEXT SIZING */
    .notification-content .summary { font-size: 1.5rem; font-weight: bold; }
    .notification-content .body { font-size: 1.1rem; }
    .notification-content .time { font-size: 0.9rem; }

    /* Remove outline */
    .notification-row { outline: none; }
  '';
in
{
  config =
    lib.mkIf (((vars.hyprland or false) || (vars.niri or false)) && !(vars.caelestia or false))
      {

        catppuccin.swaync.enable = vars.catppuccin;
        catppuccin.swaync.flavor = vars.catppuccinFlavor;

        services.swaync = {
          enable = true;
          settings = {
            positionX = "right";
            positionY = "top";
            notification-icon-size = 64;

            layer = "overlay";
            control-center-layer = "overlay";

            timeout = 10;
            timeout-low = 5;
            timeout-critical = 0;

            # Host optional rules to exclude/mute notifications
            notification-visibility = { } // vars.swayncExclusions or { };
          };

          # 🎨 DYNAMIC STYLE LOGIC
          style =
            if vars.catppuccin then
              lib.mkForce ''
                @import "${config.catppuccin.sources.swaync}/${vars.catppuccinFlavor}.css";
                ${customLayout}
              ''
            else
              lib.mkAfter ''
                ${customLayout}
              '';
        };
      };
}
