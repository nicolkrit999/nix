{
  delib,
  pkgs,
  lib,
  config,
  ...
}:
delib.module {
  name = "programs.swaync";
  options.programs.swaync = with delib; {
    enable = boolOption true;
  };

  home.ifEnabled =
    {

      nixos,
      cfg,
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

      # Enable swaync only if using Hyprland or Niri without Caelestia/Noctalia
      hyprlandSwayNC =
        (nixos.constants.hyprland or false)
        && !((nixos.constants.hyprlandCaelestia or false) || (nixos.constants.hyprlandNoctalia or false));

      niriSwayNC = (nixos.constants.niri or false) && !(nixos.constants.niriNoctalia or false);
    in
    {
      config = lib.mkIf (hyprlandSwayNC || niriSwayNC) {

        catppuccin.swaync.enable = nixos.constants.catppuccin or false;
        catppuccin.swaync.flavor = nixos.constants.catppuccinFlavor or "mocha";

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
            notification-visibility = { } // nixos.constants.swayncExclusions or { };
          };

          # 🎨 DYNAMIC STYLE LOGIC
          style =
            if nixos.constants.catppuccin then
              lib.mkForce ''
                @import "${config.catppuccin.sources.swaync}/${nixos.constants.catppuccinFlavor}.css";
                ${customLayout}
              ''
            else
              lib.mkAfter ''
                ${customLayout}
              '';
        };

        systemd.user.services.swaync = {
          Unit.PartOf = lib.mkForce (
            (lib.optional hyprlandSwayNC "hyprland-session.target") ++ (lib.optional niriSwayNC "niri.service")
          );
          Unit.After = lib.mkForce (
            (lib.optional hyprlandSwayNC "hyprland-session.target") ++ (lib.optional niriSwayNC "niri.service")
          );
          Install.WantedBy = lib.mkForce (
            (lib.optional hyprlandSwayNC "hyprland-session.target") ++ (lib.optional niriSwayNC "niri.service")
          );
        };
      };
    };
}
