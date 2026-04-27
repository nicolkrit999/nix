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

      # Extract monitor names from parent.mango.monitors entries like
      # "name:^DP-1$,width:..." → "DP-1". Used to spawn one waybar bar per
      # monitor so per-monitor modules (tags/layout/window) reflect THIS
      # monitor's state rather than always showing the first output's data.
      extractMonitorName = monStr:
        let m = builtins.match ".*name:\\^?([^$,]+)\\$?,.*" monStr;
        in if m != null then builtins.head m else null;
      monitorNames = lib.filter (n: n != null)
        (map extractMonitorName (parent.mango.monitors or [ ]));

      mkPerMonitorModules = mon: {
        # Mango uses tags (1-9, dwl-style), not workspaces. `mmsg -o ${mon} -g -t`
        # scopes the query to this monitor so each bar shows its own tag state.
        "custom/tags" = {
          exec = ''
            mmsg -o ${mon} -g -t 2>/dev/null \
              | awk -v active='${c.base0D}' -v occupied='${c.base07}' -v empty='${c.base04}' '
                  /^[^ ]+ tag [0-9]+ / {
                    id = $3 + 0
                    selected = $4 + 0
                    has_client = $5 + 0
                    if (has_client > 0) occ[id] = 1
                    if (selected > 0) act[id] = 1
                  }
                  END {
                    out = ""
                    for (i = 1; i <= 9; i++) {
                      if (act[i])      out = out "<span color=\"" active   "\" weight=\"bold\">  " i "  </span>"
                      else if (occ[i]) out = out "<span color=\"" occupied "\">  " i "  </span>"
                    }
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
            layout=$(mmsg -o ${mon} -g -l 2>/dev/null | awk '{print $NF; exit}')
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
          # mmsg -s applies to the focused monitor — there's no -o for set-layout.
          # Click toggles the focused monitor's layout (no longer monitor-pinned).
          # NOTE: mmsg -s -l accepts the layout symbol (S/T/...), not the name.
          on-click = "sh -c 'sel=$(mmsg -g -o 2>/dev/null | awk \"\\$2 == \\\"selmon\\\" && \\$3 == \\\"1\\\" { print \\$1; exit }\"); cur=$(mmsg -o \"$sel\" -g -l 2>/dev/null | awk \"{print \\$NF; exit}\"); if [ \"$cur\" = \"S\" ]; then mmsg -s -l T; else mmsg -s -l S; fi'";
          on-click-right = "mmsg -s -l S";
          tooltip = false;
        };

        "custom/window" = {
          exec = ''
            title=$(mmsg -o ${mon} -g -c 2>/dev/null | awk '$2 == "title" { $1=""; $2=""; sub(/^ +/, ""); print; exit }')
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
            layout=$(mmsg -g -k 2>/dev/null | head -1 | awk '{print $NF}')
            case "$layout" in
              us*|en*|eng*) echo "${cfg.waybarLayout."format-en" or "EN"}" ;;
              it*|ita*)     echo "${cfg.waybarLayout."format-it" or "IT"}" ;;
              de*|deu*)     echo "${cfg.waybarLayout."format-de" or "DE"}" ;;
              fr*|fra*)     echo "${cfg.waybarLayout."format-fr" or "FR"}" ;;
              *)            echo "$layout" ;;
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
      focusedSel = "$(mmsg -g -o 2>/dev/null | awk '$2 == \"selmon\" && $3 == \"1\" { print $1; exit }')";
      bars =
        if monitorNames != [ ]
        then map mkBar monitorNames
        else [ (waybarConfig // (mkPerMonitorModules focusedSel)) ];

      configDir = "waybar-mango";
    in
    {
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
