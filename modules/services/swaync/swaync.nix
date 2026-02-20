{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  # 🌟 Aligned the module name to match how you toggle it in default.nix
  name = "services.swaync";
  options.services.swaync = with delib; {
    enable = boolOption true;
    customSettings = attrsOption { };
  };

  # 🌟 Changed to home.ifEnabled because SwayNC is a user-level GUI program
  home.ifEnabled =
    {
      cfg,
      myconfig,
      config, # 🌟 Added 'config' so your Catppuccin CSS path works!
      ...
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

      # 🌟 Corrected to check 'programs.hyprland.enable' instead of 'constants.hyprland'
      hyprlandSwayNC =
        (myconfig.programs.hyprland.enable or false)
        && !(
          (myconfig.programs.caelestia.enableOnHyprland or false)
          || (myconfig.programs.noctalia.enableOnHyprland or false)
        );

      niriSwayNC =
        (myconfig.programs.niri.enable or false) && !(myconfig.programs.noctalia.enableOnNiri or false);
    in
    # 🌟 THE FIX: Removed the '{ config = ' wrapper. Return lib.mkIf directly!
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

        # 🎨 DYNAMIC STYLE LOGIC
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
