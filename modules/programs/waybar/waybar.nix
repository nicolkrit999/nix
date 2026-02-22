{
  delib,
  pkgs,
  lib,
  config,
  ...
}:
delib.module {
  name = "programs.waybar";
  options.programs.waybar = with delib; {
    enable = boolOption true;
    waybarLayout = attrsOption { }; # 🌟 Moved here
    waybarWorkspaceIcons = attrsOption { }; # 🌟 Moved here
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      c = config.lib.stylix.colors.withHashtag;
      cssVariables = ''
        @define-color base00 ${c.base00};
        @define-color base01 ${c.base01};
        @define-color base02 ${c.base02};
        @define-color base03 ${c.base03};
        @define-color base04 ${c.base04};
        @define-color base05 ${c.base05};
        @define-color base06 ${c.base06};
        @define-color base07 ${c.base07};
        @define-color base08 ${c.base08};
        @define-color base09 ${c.base09};
        @define-color base0A ${c.base0A};
        @define-color base0B ${c.base0B};
        @define-color base0C ${c.base0C};
        @define-color base0D ${c.base0D};
        @define-color base0E ${c.base0E};
        @define-color base0F ${c.base0F};
      '';
      cssContent = builtins.readFile ./style.css;
      # 1. Hyprland logic: Show Waybar if no custom shell is set
      hyprlandWaybar =
        (myconfig.programs.hyprland.enable or false)
        && !(
          (myconfig.programs.caelestia.enableOnHyprland or false)
          || (myconfig.programs.noctalia.enableOnHyprland or false)
        );

      niriWaybar =
        (myconfig.programs.niri.enable or false) && !(myconfig.programs.noctalia.enableOnNiri or false);

      isWaybarNeeded = hyprlandWaybar || niriWaybar;
    in
    lib.mkIf isWaybarNeeded {

      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
        };
        style = lib.mkAfter ''
          ${cssVariables}
          ${cssContent}
        '';

        settings = {
          mainBar = {
            layer = "top";
            position = "top";
            height = 40;

            modules-left = [
              "hyprland/workspaces"
              "niri/workspaces"
            ];

            modules-center = [
              "hyprland/window"
              "niri/window"
            ];

            modules-right = [
              "hyprland/language"
              "niri/language"
              "custom/weather"
              "pulseaudio"
              "battery"
              "clock"
              "tray"
            ];

            # Workspaces Icon and layout
            # A user may define host-specific icons (optional) in myconfig.constants.waybarWorkspaceIcons
            "hyprland/workspaces" = {
              disable-scroll = true;
              show-special = true;
              special-visible-only = true;
              all-outputs = false;
              format = "{name} {icon}";
              format-icons = cfg.waybarWorkspaceIcons;
            };

            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                active = "";
                default = "";
              };
            };

            "niri/window" = {
              format = "{}";
              separate-outputs = true;
            };

            # Languages flags and/or text
            # A user may define host-specific layout text (optional) in myconfig.constants.waybarLayout
            "hyprland/language" = {
              min-length = 5;
              tooltip = true;
              on-click = "hyprctl switchxkblayout all next";
            }
            // cfg.waybarLayout;

            "niri/language" = {
              format = "{}";
              # This command cycles to the next configured layout in Niri
              on-click = "niri msg action switch-layout-next";
            }

            // cfg.waybarLayout;

            "custom/weather" = {
              format = "<span color='${c.base0C}'>${myconfig.constants.weather or "London"}:</span> {} ";

              exec =
                let
                  weatherLoc = myconfig.constants.weather or "London";
                in
                "curl -s 'wttr.in/${weatherLoc}?format=%c%t' | sed 's/ //'";

              interval = 300;
              class = "weather";

              on-click = ''xdg-open "https://wttr.in/${myconfig.constants.weather or "London"}"'';
            };

            "pulseaudio" = {
              format = "<span color='${c.base0D}'>{icon}</span> {volume}%";
              format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}% ";
              format-muted = "<span color='${c.base08}'></span> Muted";
              format-icons = {
                "headphones" = "";
                "handsfree" = "";
                "headset" = "";
                "phone" = "";
                "portable" = "";
                "car" = "";
                "default" = [
                  ""
                  ""
                ];
              };
              on-click = "pavucontrol";
            };

            "battery" = {
              states = {
                warning = 20;
                critical = 5;
              };
              format = "<span color='${c.base0A}'>{icon}</span> {capacity}%";
              format-charging = "<span color='${c.base0B}'></span> {capacity}%";
              format-alt = "{time} <span color='${c.base0A}'>{icon}</span>";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
            };

            "clock" = {
              format = "{:%A, %B %d at %I:%M %p}"; # Click Format: Full Day Name, Month, Date... When the module is clicked it switches between formats
              format-alt = "{:%m/%d/%Y - %I:%M %p}"; # Standard Format: MM/DD/YYYY - HH:MM AM/PM
              tooltip-format = "<tt><small>{calendar}</small></tt>"; # Tooltip Format: Small calendar in tooltip
              calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
              };
            };

            # General app tray settings
            "tray" = {
              icon-size = 20;
              spacing = 8;
            };
          };
        };
      };

      systemd.user.services.waybar = {
        Unit.PartOf = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
        Unit.After = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
        Install.WantedBy = lib.mkForce (
          (lib.optional hyprlandWaybar "hyprland-session.target") ++ (lib.optional niriWaybar "niri.service")
        );
      };
    };
}
