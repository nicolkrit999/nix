{ delib
, lib
, config

, ...
}:
delib.module {
  name = "services.swaync";
  options = with delib; moduleOptions {
    enable = boolOption true;
    customSettings = attrsOption { };
  };

  # Skip entirely on Darwin - swaync is a Wayland notification daemon (Linux-only)
  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
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

      # Three-way active check: a shell only suppresses swaync when it is
      # actually running on that WM (master enable + per-WM flag + wm.enable),
      # not just when the dormant per-WM preference is set.
      caelestiaActiveOnHyprland =
        (myconfig.programs.caelestia.enable or false)
        && (myconfig.programs.caelestia.enableOnHyprland or false)
        && (myconfig.programs.hyprland.enable or false);

      noctaliaActiveOnHyprland =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnHyprland or false)
        && (myconfig.programs.hyprland.enable or false);

      noctaliaActiveOnNiri =
        (myconfig.programs.noctalia.enable or false)
        && (myconfig.programs.noctalia.enableOnNiri or false)
        && (myconfig.programs.niri.enable or false);

      hyprlandSwayNC =
        (myconfig.programs.hyprland.enable or false)
        && !(caelestiaActiveOnHyprland || noctaliaActiveOnHyprland);

      niriSwayNC =
        (myconfig.programs.niri.enable or false) && !noctaliaActiveOnNiri;
    in


    lib.mkIf (hyprlandSwayNC || niriSwayNC) {

      catppuccin.swaync.enable = myconfig.constants.theme.catppuccin or false;
      catppuccin.swaync.flavor = myconfig.constants.theme.catppuccinFlavor or "mocha";

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
          notification-visibility = { } // cfg.customSettings;
        };

        style =
          if (myconfig.constants.theme.catppuccin or false) then
            lib.mkForce ''
              @import "${config.catppuccin.sources.swaync}/${
                myconfig.constants.theme.catppuccinFlavor or "mocha"
              }.css";
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
