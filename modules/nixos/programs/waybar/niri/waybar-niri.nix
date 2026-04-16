{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-niri";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
      # Note: waybarWorkspaceIcons not used for niri (uses index format)
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

      # Guard: Niri must be enabled AND noctalia not enabled on Niri
      # Note: No caelestia check — caelestia is hyprland-only
      isNiriEnabled = parent.niri.enable or false;
      hasCustomShell = parent.noctalia.enableOnNiri or false;
      isWaybarNeeded = isNiriEnabled && !hasCustomShell;

      # Waybar config as Nix attrset
      waybarConfig = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 8;
        margin-bottom = 0;
        margin-left = 16;
        margin-right = 16;

        modules-left = [ "niri/workspaces" ];
        modules-center = [ "clock" "custom/window" ];
        modules-right =
          [ "niri/language" "custom/weather" "custom/wifi" "custom/bluetooth" "pulseaudio" "battery" ]
          ++ (lib.optional (myconfig.services.swaync.enable or false) "custom/notification");

        "niri/workspaces" = {
          format = "{index}";
          on-click = "activate";
        };

        "custom/window" = {
          exec = ''
            title=$(niri msg -j focused-window 2>/dev/null | ${pkgs.jq}/bin/jq -r '.title // empty' 2>/dev/null)
            if [ -z "$title" ] || [ "$title" = "null" ]; then
              echo "${myconfig.constants.user or "nix"}<span font_family='JetBrainsMono Nerd Font Propo'>󱄅</span>${myconfig.constants.hostname or "nixos"}"
            else
              printf "%.25s" "$title"
            fi
          '';
          interval = 1;
          tooltip = false;
        };

        "niri/language" = {
          format = "{}";
          on-click = "niri msg action switch-layout-next";
        } // cfg.waybarLayout;

        "custom/weather" = {
          format = "{}";
          exec = "curl -s 'wttr.in/${myconfig.constants.weather or "London"}?format=%c%t' | sed 's/ //'";
          interval = 300;
          class = "weather";
          on-click = "xdg-open \"https://wttr.in/${myconfig.constants.weather or "London"}\"";
        };

        "pulseaudio" = {
          format = "<span color='${c.base0D}'>{icon}</span> {volume}%{format_source}";
          format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}% {format_source}";
          format-muted = "<span color='${c.base08}'>󰖁</span> Muted{format_source}";
          format-source = " │ <span color='${c.base0B}'>󰍬</span>";
          format-source-muted = " │ <span color='${c.base08}'>󰍭</span>";
          format-icons = {
            headphones = "󰋋";
            handsfree = "󰋎";
            headset = "󰋎";
            phone = "󰏲";
            portable = "󰏲";
            car = "󰄋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pavucontrol";
        };

        "battery" = {
          states = { warning = 20; critical = 5; };
          format = "<span color='${c.base0A}'>{icon}</span> {capacity}%";
          format-charging = "<span color='${c.base0B}'>󰂄</span> {capacity}%";
          format-alt = "{time} <span color='${c.base0A}'>{icon}</span>";
          format-icons = [ "󰂎" "󰁻" "󰁾" "󰂀" "󰁹" ];
        };

        "clock" = {
          locale = myconfig.constants.mainLocale or "en_US.UTF-8";
          format = "<span color='${c.base0E}'></span> {:%I:%M %p}";
          format-alt = "<span color='${c.base0E}'></span> {:%m/%d/%Y - %I:%M %p}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
          };
        };

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

        "custom/wifi" = {
          format = "{}";
          exec = ''
            wifi_info=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
            if [ -n "$wifi_info" ]; then
              echo "<span color='${c.base0C}'>󰤨</span> $wifi_info"
            elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q "ethernet:connected"; then
              echo "<span color='${c.base0C}'>󰈀</span> ${myconfig.constants.hostname or "nixos"}"
            else
              echo "<span color='${c.base03}'>󰤭</span> offline"
            fi
          '';
          interval = 5;
          on-click = "nm-connection-editor";
          tooltip = false;
        };

        "custom/bluetooth" = {
          format = "{}";
          exec = ''
            if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
              echo "<span color='${c.base0D}'>󰂯</span>"
            else
              echo "<span color='${c.base03}'>󰂲</span>"
            fi
          '';
          interval = 5;
          on-click = "blueman-manager";
          tooltip = false;
        };
      };

      configDir = "waybar-niri";
    in
    lib.mkIf isWaybarNeeded {
      # Write config and style to separate directory
      xdg.configFile."${configDir}/config".text = builtins.toJSON waybarConfig;
      xdg.configFile."${configDir}/style.css".text = ''
        ${cssVariables}
        ${cssContent}
      '';

      # Custom systemd service for Niri waybar
      systemd.user.services.waybar-niri = {
        Unit = {
          Description = "Waybar for Niri";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "niri.service" ];
          After = [ "niri.service" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${pkgs.waybar}/bin/waybar -c %h/.config/${configDir}/config -s %h/.config/${configDir}/style.css";
          ExecReload = "${pkgs.coreutils}/bin/kill -SIGUSR2 $MAINPID";
          Restart = "on-failure";
          RestartSec = 1;
          KillMode = "mixed";
        };
        Install = {
          WantedBy = [ "niri.service" ];
        };
      };
    };
}
