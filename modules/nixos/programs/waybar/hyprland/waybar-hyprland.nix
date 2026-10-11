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
      keyboardName = strOption "";
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      # Patch waybar to fix workspace-click regression introduced by Hyprland 0.54+
      # lua-based IPC dispatch. Built-in click handler used old-style "dispatch workspace N"
      # which Hyprland now rejects. PR #5013 (merged, unreleased as of 2026-06-02).
      waybarPatched = pkgs.waybar.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./waybar-hyprland-lua-dispatch.patch ];
      });
      c = config.lib.stylix.colors.withHashtag;
      t = (import ../contrast-lib.nix { inherit lib; }).mkTheme c;
      cssVariables = t.cssVariables;

      cssContent = builtins.readFile ./style.css;

      isHyprlandEnabled = parent.hyprland.enable or false;
      caelestiaActiveOnHyprland =
        (parent.caelestia.enable or false)
        && (parent.caelestia.enableOnHyprland or false);
      noctaliaActiveOnHyprland =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnHyprland or false);
      hasShellOnHyprland = caelestiaActiveOnHyprland || noctaliaActiveOnHyprland;

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
          [ "hyprland/language" "custom/weather" "custom/wifi" "custom/bluetooth" "pulseaudio" "custom/mic" "battery" ]
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
        } // (
          if cfg.keyboardName != "" then {
            on-click = "hyprctl switchxkblayout ${cfg.keyboardName} next";
            keyboard-name = cfg.keyboardName;
          } else {
            on-click = "hyprctl switchxkblayout all next";
          }
        ) // cfg.waybarLayout;

        "custom/weather" = {
          format = "{}";
          exec = "curl -s 'wttr.in/${myconfig.constants.weather or "London"}?format=%c%t' | sed 's/ //'";
          interval = 300;
          class = "weather";
          on-click = "xdg-open \"https://wttr.in/${myconfig.constants.weather or "London"}\"";
        };

        "pulseaudio" = {
          format = "<span color='${t.accent c.base0D}'>{icon}</span> {volume}%";
          format-bluetooth = "<span color='${t.accent c.base0D}'>{icon}</span> {volume}%";
          format-muted = "<span color='${t.accent c.base08}'>󰖁</span> Muted";
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

        "custom/mic" = {
          format = "{}";
          exec = ''
            if ! wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1; then
              echo "<span color='${t.accent c.base08}'>󰍭</span>"
            elif wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
              echo "<span color='${t.accent c.base08}'>󰍭</span>"
            else
              echo "<span color='${t.accent c.base0B}'>󰍬</span>"
            fi
          '';
          interval = 1;
          on-click = "wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          tooltip = false;
        };

        "battery" = {
          states = { warning = 20; critical = 5; };
          format = "<span color='${t.accent c.base0A}'>{icon}</span> {capacity}%";
          format-charging = "<span color='${t.accent c.base0B}'>󰂄</span> {capacity}%";
          format-critical = "<span color='${t.fg.crit}'>{icon}</span> {capacity}% {time}";
          format-alt = "{time} <span color='${t.accent c.base0A}'>{icon}</span>";
          format-icons = [ "󰂎" "󰁻" "󰁾" "󰂀" "󰁹" ];
        };

        "clock" = {
          locale = myconfig.constants.mainLocale or "en_US.UTF-8";
          format = "<span color='${t.accent c.base0E}'></span> {:%I:%M %p}";
          format-alt = "<span color='${t.accent c.base0E}'></span> {:%m/%d/%Y - %I:%M %p}";
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
              echo "<span color='${t.accent c.base09}'>󰂚</span> $count"
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
              echo "<span color='${t.accent c.base0C}'>󰤨</span> $wifi_info"
            elif nmcli -t -f TYPE,STATE dev 2>/dev/null | grep -q "ethernet:connected"; then
              echo "<span color='${t.accent c.base0C}'>󰈀</span> ${myconfig.constants.hostname or "nixos"}"
            else
              echo "<span color='${t.fg.pill}'>󰤭</span> offline"
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
              echo "<span color='${t.accent c.base0D}'>󰂯</span>"
            else
              echo "<span color='${t.fg.pill}'>󰂲</span>"
            fi
          '';
          interval = 5;
          on-click = "blueman-manager";
          tooltip = false;
        };
      };

      configDir = "waybar-hyprland";
    in
    {
      home.packages = [ pkgs.nerd-fonts.jetbrains-mono ];
      fonts.fontconfig.enable = true;

      assertions = [
        {
          assertion = !(isHyprlandEnabled && hasShellOnHyprland);
          message = "waybar-hyprland is enabled together with an active shell (caelestia or noctalia) on Hyprland - disable one.";
        }
      ];

      xdg.configFile."${configDir}/config" = lib.mkIf isHyprlandEnabled {
        text = builtins.toJSON waybarConfig;
      };
      xdg.configFile."${configDir}/style.css" = lib.mkIf isHyprlandEnabled {
        text = ''
          ${cssVariables}
          ${cssContent}
        '';
      };

      # Custom systemd service for Hyprland waybar
      systemd.user.services.waybar-hyprland = lib.mkIf isHyprlandEnabled {
        Unit = {
          Description = "Waybar for Hyprland";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "hyprland-session.target" ];
          After = [ "hyprland-session.target" ];
          ConditionEnvironment = "WAYLAND_DISPLAY";
        };
        Service = {
          ExecStart = "${waybarPatched}/bin/waybar -c %h/.config/${configDir}/config -s %h/.config/${configDir}/style.css";
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
