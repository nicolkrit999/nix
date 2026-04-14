{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-hyprland";

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

      # Guard: Hyprland must be enabled AND no custom shell (caelestia or noctalia) on Hyprland
      isHyprlandEnabled = parent.hyprland.enable or false;
      hasCustomShell = (parent.caelestia.enableOnHyprland or false)
        || (parent.noctalia.enableOnHyprland or false);
      isWaybarNeeded = isHyprlandEnabled && !hasCustomShell;

      # Waybar config as Nix attrset
      waybarConfig = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 8;
        margin-bottom = 0;
        margin-left = 16;
        margin-right = 16;

        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ "clock" "hyprland/window" ];
        modules-right =
          [ "hyprland/language" "custom/weather" "custom/wifi" "custom/bluetooth" "pulseaudio" "battery" ]
          ++ (lib.optional (myconfig.services.swaync.enable or false) "custom/notification");

        "hyprland/workspaces" = {
          disable-scroll = true;
          show-special = true;
          all-outputs = false;
          format = "{id}{icon}";
          format-icons = cfg.waybarWorkspaceIcons // { default = ""; };
        };

        "hyprland/window" = {
          format = "{}";
          icon = false;
          max-length = 25;
          separate-outputs = true;
          rewrite = {
            "^$" = "${myconfig.constants.user or "nix"}<span font_family='JetBrainsMono Nerd Font Propo'>󱄅</span>${myconfig.constants.hostname or "nixos"}";
          };
        };

        "hyprland/language" = {
          min-length = 5;
          tooltip = true;
          on-click = "hyprctl switchxkblayout all next";
        } // cfg.waybarLayout;

        "custom/weather" = {
          format = "{}";
          exec = "curl -s 'wttr.in/${myconfig.constants.weather or "London"}?format=%c%t' | sed 's/ //'";
          interval = 300;
          class = "weather";
          on-click = "xdg-open \"https://wttr.in/${myconfig.constants.weather or "London"}\"";
        };

        "pulseaudio" = {
          format = "<span color='${c.base0D}'>{icon}</span> {volume}%";
          format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}% ";
          format-muted = "<span color='${c.base08}'>󰖁</span> Muted";
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

      configDir = "waybar-hyprland";
    in
    lib.mkIf isWaybarNeeded {
      # Write config and style to separate directory
      xdg.configFile."${configDir}/config".text = builtins.toJSON waybarConfig;
      xdg.configFile."${configDir}/style.css".text = ''
        ${cssVariables}
        ${cssContent}
      '';

      # Custom systemd service for Hyprland waybar
      systemd.user.services.waybar-hyprland = {
        Unit = {
          Description = "Waybar for Hyprland";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
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
          WantedBy = [ "hyprland-session.target" ];
        };
      };
    };
}
