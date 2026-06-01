{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "programs.waybar-mango";

  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      waybarLayout = attrsOption { };
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

      isMangoEnabled = parent.mango.enable or false;
      noctaliaActiveOnMango =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnMango or false);

      # Extract monitor names from parent.mango.monitors entries like
      # "name:^DP-1$,width:..." → "DP-1". Used to spawn one waybar bar per
      # monitor so per-monitor modules (tags/layout/window) reflect THIS
      # monitor's state rather than always showing the first output's data.
      extractMonitorName = monStr:
        let m = builtins.match ".*name:\\^?([^$,]+)\\$?,.*" monStr;
        in if m != null then builtins.head m else null;
      monitorNames = lib.filter (n: n != null)
        (map extractMonitorName (parent.mango.monitors or [ ]));

      # mmsg IPC was reshaped in the 26.05 mango bump:
      #   old: `mmsg -o <mon> -g -t/-l/-c`, `mmsg -g -o/-k`, `mmsg -s -l <sym>`
      #   new: `mmsg get all-monitors|tags|focusing-client|keyboardlayout`, `mmsg dispatch <func>[,arg]`
      # All read-side modules now go through a single `mmsg get all-monitors` +
      # jq filter on `.name==$mon`, which gives us tags / layout_symbol /
      # active_client in one JSON shot per tick.
      mkPerMonitorModules = mon: {
        "custom/tags" = {
          exec = ''
            mmsg get all-monitors 2>/dev/null \
              | jq -r --arg mon "${mon}" '
                  .monitors[] | select(.name == $mon) | .tags[] |
                    if .is_active then "A \(.index)"
                    elif (.client_count // 0) > 0 then "O \(.index)"
                    else empty end' \
              | awk -v active='${c.base0D}' -v occupied='${c.base07}' -v empty='${c.base04}' '
                  $1 == "A" { out = out "<span color=\"" active "\" weight=\"bold\">  " $2 "  </span>" }
                  $1 == "O" { out = out "<span color=\"" occupied "\">  " $2 "  </span>" }
                  END {
                    if (out == "") out = "<span color=\"" empty "\">  -  </span>"
                    print out
                  }'
          '';
          format = "{}";
          interval = 1;
          tooltip = false;
        };

        "custom/layout" = {
          format = "{}";
          exec = ''
            layout=$(mmsg get all-monitors 2>/dev/null \
              | jq -r --arg mon "${mon}" '.monitors[] | select(.name == $mon) | .layout_symbol // ""')
            case "$layout" in
              S)   echo "<span color='${c.base0C}'>󰕕</span> Scroller" ;;
              T)   echo "<span color='${c.base0D}'>󰕴</span> Tile" ;;
              M)   echo "<span color='${c.base0E}'>󰊓</span> Mono" ;;
              G)   echo "<span color='${c.base0A}'>󰕰</span> Grid" ;;
              K)   echo "<span color='${c.base0B}'>󰓹</span> Deck" ;;
              CT)  echo "<span color='${c.base0D}'>󰃻</span> Center" ;;
              VT)  echo "<span color='${c.base0D}'>󰬔</span> VTile" ;;
              VS)  echo "<span color='${c.base0C}'>󰬔</span> VScroll" ;;
              VG)  echo "<span color='${c.base0A}'>󰬔</span> VGrid" ;;
              VK)  echo "<span color='${c.base0B}'>󰬔</span> VDeck" ;;
              RT)  echo "<span color='${c.base0D}'>󰕴</span> RTile" ;;
              TG)  echo "<span color='${c.base0F}'>󱁻</span> TGMix" ;;
              *)   echo "$layout" ;;
            esac
          '';
          interval = 1;
          # `dispatch` targets the focused monitor; toggle S<->T based on its current symbol.
          on-click = "sh -c 'cur=$(mmsg get all-monitors 2>/dev/null | jq -r \".monitors[] | select(.active == true) | .layout_symbol\"); if [ \"$cur\" = \"S\" ]; then mmsg dispatch setlayout,T; else mmsg dispatch setlayout,S; fi'";
          on-click-right = "mmsg dispatch setlayout,S";
          tooltip = false;
        };

        "custom/window" = {
          exec = ''
            title=$(mmsg get all-monitors 2>/dev/null \
              | jq -r --arg mon "${mon}" '.monitors[] | select(.name == $mon) | .active_client.title // ""')
            if [ -z "$title" ] || [ "$title" = "null" ]; then
              echo "${myconfig.constants.user or "nix"}<span font_family='JetBrainsMono Nerd Font Propo'>󱄅</span>${myconfig.constants.hostname or "nixos"}"
            else
              printf "%.25s" "$title"
            fi
          '';
          interval = 1;
          tooltip = false;
        };
      };

      waybarConfig = {
        layer = "top";
        position = "top";
        height = 36;
        margin-top = 8;
        margin-bottom = 0;
        margin-left = 16;
        margin-right = 16;

        modules-left = [ "custom/tags" "custom/layout" ];
        modules-center = [ "clock" "custom/window" ];
        modules-right =
          [ "custom/language" "custom/weather" "custom/wifi" "custom/bluetooth" "pulseaudio" "custom/mic" "battery" ]
          ++ (lib.optional (myconfig.services.swaync.enable or false) "custom/notification");

        "custom/language" = {
          format = "{}";
          exec = ''
            layout=$(mmsg get keyboardlayout 2>/dev/null | jq -r '.layout // ""')
            case "$layout" in
              English*|US*|us*|en*) echo "${cfg.waybarLayout."format-en" or "EN"}" ;;
              Italian*|it*|ita*)    echo "${cfg.waybarLayout."format-it" or "IT"}" ;;
              German*|de*|deu*)     echo "${cfg.waybarLayout."format-de" or "DE"}" ;;
              French*|fr*|fra*)     echo "${cfg.waybarLayout."format-fr" or "FR"}" ;;
              *)                    echo "$layout" ;;
            esac
          '';
          interval = 2;
          tooltip = false;
        };

        "custom/weather" = {
          format = "{}";
          exec = "curl -s 'wttr.in/${myconfig.constants.weather or "London"}?format=%c%t' | sed 's/ //'";
          interval = 300;
          class = "weather";
          on-click = "xdg-open \"https://wttr.in/${myconfig.constants.weather or "London"}\"";
        };

        "pulseaudio" = {
          format = "<span color='${c.base0D}'>{icon}</span> {volume}%";
          format-bluetooth = "<span color='${c.base0D}'>{icon}</span> {volume}%";
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

        "custom/mic" = {
          format = "{}";
          exec = ''
            if ! wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1; then
              echo "<span color='${c.base08}'>󰍭</span>"
            elif wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | grep -q MUTED; then
              echo "<span color='${c.base08}'>󰍭</span>"
            else
              echo "<span color='${c.base0B}'>󰍬</span>"
            fi
          '';
          interval = 1;
          on-click = "wpctl inspect @DEFAULT_AUDIO_SOURCE@ >/dev/null 2>&1 && wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          tooltip = false;
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

      # One bar per detected monitor, each with its monitor name baked into the
      # per-monitor exec scripts. Waybar's `output` field pins each bar to its
      # output, and JSON config can be a list of bar objects.
      mkBar = mon: waybarConfig // (mkPerMonitorModules mon) // { output = mon; };
      # Fallback when monitor names aren't parseable from parent.mango.monitors:
      # one bar (replicated on every output) that always shows the focused
      # monitor's data via runtime selmon lookup.
      focusedSel = "$(mmsg get all-monitors 2>/dev/null | jq -r '.monitors[] | select(.active == true) | .name' | head -1)";
      bars =
        if monitorNames != [ ]
        then map mkBar monitorNames
        else [ (waybarConfig // (mkPerMonitorModules focusedSel)) ];

      configDir = "waybar-mango";
    in
    {
      assertions = [
        {
          assertion = !(isMangoEnabled && noctaliaActiveOnMango);
          message = "waybar-mango is enabled together with an active noctalia shell on Mango — disable one.";
        }
      ];

      xdg.configFile."${configDir}/config" = lib.mkIf isMangoEnabled {
        text = builtins.toJSON bars;
      };
      xdg.configFile."${configDir}/style.css" = lib.mkIf isMangoEnabled {
        text = ''
          ${cssVariables}
          ${cssContent}
        '';
      };

      systemd.user.services.waybar-mango = lib.mkIf isMangoEnabled {
        Unit = {
          Description = "Waybar for Mango";
          Documentation = "https://github.com/Alexays/Waybar/wiki";
          PartOf = [ "mango-session.target" ];
          After = [ "mango-session.target" ];
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
          WantedBy = [ "mango-session.target" ];
        };
      };
    };
}
