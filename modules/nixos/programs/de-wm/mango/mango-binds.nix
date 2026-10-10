{ delib
, inputs
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.mango";
  options =
    with delib;
    moduleOptions {
      extraBinds = listOfOption str [ ];
      extraMouseBinds = listOfOption str [ ];
      extraAxisBinds = listOfOption str [ ];
      extraLayerRules = listOfOption str [ ];
    };

  home.ifEnabled =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      term = myconfig.constants.terminal.name;
      browser = myconfig.constants.browser;
      editor = myconfig.constants.editor;
      fileManager = myconfig.constants.fileManager;

      termApps = myconfig.constants.terminalApps;
      smartLaunch =
        app: if builtins.elem app termApps then "${term} --class ${app} -e ${app}" else app;

      screenshotsDir = myconfig.constants.screenshots;

      mangoScreenshot = pkgs.writeShellApplication {
        name = "mango-screenshot";
        runtimeInputs = [ pkgs.grim pkgs.slurp pkgs.wl-clipboard pkgs.libnotify pkgs.jq pkgs.coreutils ];
        text = ''
          mkdir -p "${screenshotsDir}"
          stamp=$(date +%Y%m%d-%H%M%S)
          case ''${1:-output} in
            area)
              region=$(slurp) || exit 0
              f="${screenshotsDir}/area-$stamp.png"
              grim -g "$region" "$f"
              ;;
            *)
              out=$(mmsg get all-monitors | jq -r '[.monitors[] | select(.active) | .name][0] // empty')
              f="${screenshotsDir}/screenshot-$stamp.png"
              if [[ -n $out ]]; then grim -o "$out" "$f"; else grim "$f"; fi
              ;;
          esac
          wl-copy < "$f"
          notify-send "Screenshot" "Saved $f"
        '';
      };

      mangoPip = pkgs.writeShellApplication {
        name = "mango-pip";
        runtimeInputs = [ pkgs.jq pkgs.coreutils ];
        text = ''
          q() { mmsg get focusing-client | jq -r "$1" 2>/dev/null || echo null; }

          id=$(q '.id | tostring')
          if [[ $id == null ]]; then exit 0; fi
          dir="''${XDG_RUNTIME_DIR:-/tmp}/mango-pip"
          mkdir -p "$dir"

          if [[ $(q '.is_global | tostring') == true ]]; then
            mmsg dispatch toggleglobal
            if [[ -e $dir/$id ]]; then
              rm -f "$dir/$id"
            elif [[ $(q '.is_floating | tostring') == true ]]; then
              mmsg dispatch togglefloating
            fi
            exit 0
          fi

          floating=$(q '.is_floating | tostring')
          if [[ $floating == null ]]; then exit 0; fi
          if [[ $floating == false ]]; then
            mmsg dispatch togglefloating
          else
            touch "$dir/$id"
          fi
          if [[ $(q '.is_floating | tostring') == true ]]; then
            mmsg dispatch resizewin,800,450
            mmsg dispatch toggleglobal
          fi
        '';
      };

      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

      noctaliaActiveOnMango =
        (parent.noctalia.enable or false)
        && (parent.noctalia.enableOnMango or false)
        && (parent.mango.enable or false);

      shellLauncherBind =
        if noctaliaActiveOnMango then
          "SUPER+SHIFT,A,spawn,sh -c '${noctaliaPkg}/bin/noctalia-shell ipc call launcher toggle'"
        else
          "SUPER+SHIFT,A,spawn,true";

      shellLockBind =
        if noctaliaActiveOnMango then
          "SUPER,Delete,spawn,sh -c '${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock'"
        else
          "SUPER,Delete,spawn,loginctl lock-session";

      mediaSymBinds =
        if noctaliaActiveOnMango then [
          "NONE,XF86AudioPause,spawn,playerctl play-pause"
          "NONE,XF86AudioPlay,spawn,playerctl play-pause"
        ] else [
          "NONE,XF86AudioPause,spawn,swayosd-client --playerctl play-pause"
          "NONE,XF86AudioPlay,spawn,swayosd-client --playerctl play-pause"
        ];

      mediaBinds =
        if noctaliaActiveOnMango then [
          "SUPER,BracketRight,spawn,brightnessctl set 5%+"
          "SUPER,BracketLeft,spawn,brightnessctl set 5%-"
          "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
          "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          "NONE,XF86MonBrightnessUp,spawn,brightnessctl set 5%+"
          "NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"
          "NONE,XF86KbdBrightnessUp,spawn,brightnessctl --device='*::kbd_backlight' set +10%"
          "NONE,XF86KbdBrightnessDown,spawn,brightnessctl --device='*::kbd_backlight' set 10%-"
          "NONE,XF86AudioNext,spawn,playerctl next"
          "NONE,XF86AudioPrev,spawn,playerctl previous"
          "NONE,XF86AudioStop,spawn,playerctl stop"
        ] else [
          "SUPER,BracketRight,spawn,swayosd-client --brightness raise"
          "SUPER,BracketLeft,spawn,swayosd-client --brightness lower"
          "NONE,XF86AudioRaiseVolume,spawn,swayosd-client --output-volume raise"
          "NONE,XF86AudioLowerVolume,spawn,swayosd-client --output-volume lower"
          "NONE,XF86AudioMute,spawn,swayosd-client --output-volume mute-toggle"
          "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          "NONE,XF86MonBrightnessUp,spawn,swayosd-client --brightness raise"
          "NONE,XF86MonBrightnessDown,spawn,swayosd-client --brightness lower"
          "NONE,XF86KbdBrightnessUp,spawn,swayosd-client --keyboard-brightness raise"
          "NONE,XF86KbdBrightnessDown,spawn,swayosd-client --keyboard-brightness lower"
          "NONE,XF86AudioNext,spawn,swayosd-client --playerctl next"
          "NONE,XF86AudioPrev,spawn,swayosd-client --playerctl previous"
          "NONE,XF86AudioStop,spawn,swayosd-client --playerctl stop"
          "NONE,Caps_Lock,spawn,swayosd-client --caps-lock"
        ];

      baseBinds = [
        "SUPER,Return,spawn,${term}"
        "SUPER,A,spawn,vicinae toggle"
        shellLauncherBind
        "SUPER,B,spawn,${browser}"
        "SUPER,F,spawn,${smartLaunch fileManager}"
        "SUPER,C,spawn,${smartLaunch editor}"
        "SUPER,period,spawn,vicinae vicinae://launch/core/search-emojis"
        "SUPER,V,spawn,vicinae vicinae://launch/clipboard/history"
        "SUPER+SHIFT,P,spawn,hyprpicker -an"
        "SUPER,N,spawn,swaync-client -t -sw"

        shellLockBind
        "SUPER+SHIFT,Delete,quit,"
        "SUPER+SHIFT,C,killclient,"
        "SUPER,M,togglefullscreen,"
        "SUPER,Space,togglefloating,"
        "SUPER,G,toggleglobal,"
        "SUPER+ALT,P,toggleglobal,"
        "SUPER,P,spawn,${lib.getExe mangoPip}"
        "SUPER,O,toggleoverview,"
        "SUPER,I,minimized,"
        "SUPER+SHIFT,I,restore_minimized"
        "SUPER+SHIFT,R,reload_config"
        "SUPER+ALT,N,switch_layout"
        "SUPER,T,dwindle_toggle_current_split"
        "SUPER+ALT,T,setlayout,tile"
        "SUPER,S,toggle_special_tag"
        "SUPER+SHIFT,S,tag_special_tag"
        "SUPER+ALT,S,setlayout,scroller"

        "SUPER+ALT,W,spawn,pkill -SIGUSR2 waybar"
        "SUPER+SHIFT,W,spawn,pkill -x -SIGUSR1 waybar"

        "SUPER+ALT,A,togglemaximizescreen,"
        "SUPER+ALT,F,togglefakefullscreen,"
        "SUPER+ALT,Z,toggle_scratchpad"
        "SUPER+ALT,E,set_proportion,1.0"
        "SUPER+ALT,X,switch_proportion_preset,next"

        "SUPER,Tab,focusstack,next"
        "SUPER,Left,focusdir,left"
        "SUPER,H,focusdir,left"
        "SUPER,Right,focusdir,right"
        "SUPER,L,focusdir,right"
        "SUPER,Up,focusdir,up"
        "SUPER,K,focusdir,up"
        "SUPER,Down,focusdir,down"
        "SUPER,J,focusdir,down"

        "SUPER+SHIFT,Left,exchange_client,left"
        "SUPER+SHIFT,H,exchange_client,left"
        "SUPER+SHIFT,Right,exchange_client,right"
        "SUPER+SHIFT,L,exchange_client,right"
        "SUPER+SHIFT,Up,exchange_client,up"
        "SUPER+SHIFT,K,exchange_client,up"
        "SUPER+SHIFT,Down,exchange_client,down"
        "SUPER+SHIFT,J,exchange_client,down"

        "SUPER,1,view,1,0"
        "SUPER,2,view,2,0"
        "SUPER,3,view,3,0"
        "SUPER,4,view,4,0"
        "SUPER,5,view,5,0"
        "SUPER,6,view,6,0"
        "SUPER,7,view,7,0"
        "SUPER,8,view,8,0"
        "SUPER,9,view,9,0"

        "SUPER+SHIFT,1,tagsilent,1"
        "SUPER+SHIFT,2,tagsilent,2"
        "SUPER+SHIFT,3,tagsilent,3"
        "SUPER+SHIFT,4,tagsilent,4"
        "SUPER+SHIFT,5,tagsilent,5"
        "SUPER+SHIFT,6,tagsilent,6"
        "SUPER+SHIFT,7,tagsilent,7"
        "SUPER+SHIFT,8,tagsilent,8"
        "SUPER+SHIFT,9,tagsilent,9"

        "SUPER+ALT,1,tag,1,0"
        "SUPER+ALT,2,tag,2,0"
        "SUPER+ALT,3,tag,3,0"
        "SUPER+ALT,4,tag,4,0"
        "SUPER+ALT,5,tag,5,0"
        "SUPER+ALT,6,tag,6,0"
        "SUPER+ALT,7,tag,7,0"
        "SUPER+ALT,8,tag,8,0"
        "SUPER+ALT,9,tag,9,0"

        "SUPER+CTRL,Left,resizewin,-60,+0"
        "SUPER+CTRL,Right,resizewin,+60,+0"
        "SUPER+CTRL,Up,resizewin,+0,-60"
        "SUPER+CTRL,Down,resizewin,+0,+60"
        "SUPER+CTRL,H,focusmon,left"
        "SUPER+CTRL,L,focusmon,right"
        "SUPER+ALT,Left,tagmon,left"
        "SUPER+ALT,H,tagmon,left"
        "SUPER+ALT,Right,tagmon,right"
        "SUPER+ALT,L,tagmon,right"

        "SUPER,equal,incgaps,1"
        "SUPER,minus,incgaps,-1"
        "SUPER+SHIFT,G,togglegaps"

        "SUPER+CTRL+SHIFT,Up,movewin,+0,-50"
        "SUPER+CTRL+SHIFT,Down,movewin,+0,+50"
        "SUPER+CTRL+SHIFT,Left,movewin,-50,+0"
        "SUPER+CTRL+SHIFT,Right,movewin,+50,+0"

        "NONE,Print,spawn,${lib.getExe mangoScreenshot} output"
        "SUPER+CTRL,3,spawn,${lib.getExe mangoScreenshot} output"
        "SUPER+CTRL,4,spawn,${lib.getExe mangoScreenshot} area"
      ];

      baseMouseBinds = [
        "SUPER,btn_left,moveresize,curmove"
        "SUPER,btn_right,moveresize,curresize"
      ];

      baseAxisBinds = [
        "SUPER,UP,viewtoleft_have_client"
        "SUPER,DOWN,viewtoright_have_client"
      ];

      tagIds = [ 1 2 3 4 5 6 7 8 9 ];
      tagRules =
        let
          fallback = map (i: "id:${toString i},layout_name:${cfg.defaultLayout}") tagIds;
          perMonitor = lib.concatMap
            (name: map (i: "id:${toString i},monitor_name:^${name}$,layout_name:${cfg.monitorLayouts.${name}}") tagIds)
            (builtins.attrNames cfg.monitorLayouts);
        in
        fallback ++ perMonitor;

      baseGestureBinds = [
        "none,left,3,viewtoright_have_client"
        "none,right,3,viewtoleft_have_client"
        "none,up,3,togglefullscreen"
        "none,down,3,killclient"
        "none,left,4,viewtoright_have_client"
        "none,right,4,viewtoleft_have_client"
        "none,up,4,spawn,vicinae toggle"
        "none,down,4,toggle_special_tag"
      ];

      baseLayerRules = [
        "animation_type_open:zoom,layer_name:rofi"
        "animation_type_close:zoom,layer_name:rofi"
        "animation_type_open:zoom,layer_name:vicinae"
        "animation_type_close:zoom,layer_name:vicinae"
      ];
    in
    {
      wayland.windowManager.mango.settings = {
        bind = baseBinds ++ cfg.extraBinds;
        bindl = mediaBinds;
        bindsl = mediaSymBinds;
        mousebind = baseMouseBinds ++ cfg.extraMouseBinds;
        axisbind = baseAxisBinds ++ cfg.extraAxisBinds;
        gesturebind = baseGestureBinds;
        tag_rule = tagRules;
        layer_rule = baseLayerRules ++ cfg.extraLayerRules;
      };
    };
}
