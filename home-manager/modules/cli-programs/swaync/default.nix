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

  # Enable swaync only if using Hyprland or Niri without Caelestia/Noctalia
  hyprlandSwayNC =
    (vars.hyprland or false)
    && !((vars.hyprlandCaelestia or false) || (vars.hyprlandNoctalia or false));

  niriSwayNC = (vars.niri or false) && !(vars.niriNoctalia or false);
in
{
  config = lib.mkIf (hyprlandSwayNC || niriSwayNC) {

    catppuccin.swaync.enable = vars.catppuccin or false;
    catppuccin.swaync.flavor = vars.catppuccinFlavor or "mocha";

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
}
