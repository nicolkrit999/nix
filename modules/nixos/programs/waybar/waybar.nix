{ delib
, lib
, config
, ...
}:
delib.module {
  name = "programs.waybar";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
      waybarWorkspaceIcons = attrsOption { };
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
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
      # 1. hyprland logic: show waybar if no custom shell is set
      hyprlandWaybar =
        (parent.hyprland.enable or false)
        && !((parent.caelestia.enableOnHyprland or false) || (parent.noctalia.enableOnHyprland or false));

      niriWaybar = (parent.niri.enable or false) && !(parent.noctalia.enableOnNiri or false);

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
            layer = "top"; # Render above windows
            position = "top"; # Bar at top of screen
            height = 36; # Module height (sized for 14px font + 4px vertical padding)
            margin-top = 8; # Gap from screen edge to modules
            margin-bottom = 0; # 0 here + gaps_out(10) ≈ margin-top(8) — compensates for Hyprland adding gaps_out below the exclusive zone
            margin-left = 16; # Gap from left edge
            margin-right = 16; # Gap from right edge

            modules-left =
              (lib.optional hyprlandWaybar "hyprland/workspaces")
              ++ (lib.optional niriWaybar "niri/workspaces");

            modules-center =
              [ "clock" ]
              ++ (lib.optional hyprlandWaybar "hyprland/window") # Fixme: to the right there is a ghost module. Possibly a css error or special scratchpad, tough the show special is disabled
              ++ (lib.optional niriWaybar "niri/window");

            modules-right =
              (lib.optional hyprlandWaybar "hyprland/language")
              ++ (lib.optional niriWaybar "niri/language")
              ++ [
                "custom/weather"
                "custom/connectivity"
                "pulseaudio"
                "battery"
              ]
              ++ (lib.optional (myconfig.services.swaync.enable or false) "custom/notification");

            # Workspaces Icon and layout
            # A user may define host-specific icons (optional) in myconfig.constants.waybarWorkspaceIcons
            "hyprland/workspaces" = {
              disable-scroll = true;
              show-special = false; # Hide special/scratchpad workspaces
              all-outputs = false;
              format = "{name}{icon}";
              format-icons = cfg.waybarWorkspaceIcons // { default = ""; };
            };

            # niri-autoname-workspaces renames workspaces to Nerd Font app icons;
            # without it running, this falls back to the workspace index number.
            "niri/workspaces" = {
              format = "{name}";
              on-click = "activate";
            };

            "hyprland/window" = {
              format = "{}";
              max-length = 25;
              separate-outputs = true;
              rewrite = {
                "^$" = "${myconfig.constants.user or "nix"} 󱄅 ${myconfig.constants.hostname or "nixos"}";
              };
            };

            "niri/window" = {
              format = "{}";
              max-length = 25;
              separate-outputs = true;
              rewrite = {
                "^$" = "${myconfig.constants.user or "nix"} 󱄅 ${myconfig.constants.hostname or "nixos"}";
              };
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
              on-click = "niri msg action switch-layout-next";
            }

            // cfg.waybarLayout;

            "custom/weather" = {
              format = "{}";

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
              locale = myconfig.constants.mainLocale or "en_US.UTF-8";
              format = "<span color='${c.base0E}'></span> {:%I:%M %p}";
              format-alt = "<span color='${c.base0E}'></span> {:%m/%d/%Y - %I:%M %p}";
              tooltip-format = "<tt><small>{calendar}</small></tt>";
              calendar = {
                mode = "year";
                mode-mon-col = 3;
                weeks-pos = "right";
                on-scroll = 1;
              };
            };

            # Notification module: opens swaync notification center
            "custom/notification" = {
              format = "{}";
              exec = ''
                count=$(swaync-client -c 2>/dev/null || echo "0")
                if [ "$count" -gt 0 ]; then
                  echo "<span color='${c.base09}'>󰂚</span> $count"
                else
                  echo "󰂜"
                fi
              '';
              interval = 1;
              on-click = "swaync-client -t -sw";
              on-click-right = "swaync-client -C";
              tooltip = false;
            };

            # Connectivity module: network (wifi/ethernet + SSID/hostname) : bluetooth status
            "custom/connectivity" = {
              format = "{}";
              exec = let hostname = myconfig.constants.hostname or "nixos"; in ''
                wifi_info=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
                if [ -n "$wifi_info" ]; then
                  net="<span color='${c.base0C}'>󰤨</span> $wifi_info"
                elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q "ethernet:connected"; then
                  net="<span color='${c.base0C}'>󰈀</span> ${hostname}"
                else
                  net="<span color='${c.base03}'>󰤭</span> offline"
                fi
                if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
                  bt="<span color='${c.base0D}'>󰂯</span>"
                else
                  bt="<span color='${c.base03}'>󰂲</span>"
                fi
                echo "$net : $bt"
              '';
              interval = 5;
              on-click = "nm-connection-editor";
              on-click-right = "blueman-manager";
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
