{ delib
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
    , myconfig
    , ...
    }:
    let
      term = myconfig.constants.terminal.name;
      browser = myconfig.constants.browser;
      editor = myconfig.constants.editor;
      fileManager = myconfig.constants.fileManager;

      termApps = [ "nvim" "neovim" "vim" "nano" "hx" "helix" "yazi" "ranger" "lf" "nnn" ];
      smartLaunch =
        app: if builtins.elem app termApps then "${term} --class ${app} -e ${app}" else app;

      screenshotsDir = myconfig.constants.screenshots;

      baseBinds = [
        "SUPER,Return,spawn,${term}"
        "SUPER,A,spawn,walker"
        "SUPER+SHIFT,A,spawn,walker"
        "SUPER,B,spawn,${browser}"
        "SUPER,F,spawn,${smartLaunch fileManager}"
        "SUPER,C,spawn,${smartLaunch editor}"
        "SUPER,period,spawn,walker -m symbols"
        "SUPER,V,spawn,walker -m clipboard"
        "SUPER+SHIFT,P,spawn,hyprpicker -an"
        "SUPER,N,spawn,swaync-client -t -sw"

        "SUPER,Delete,spawn,loginctl lock-session"
        "SUPER+SHIFT,Delete,quit,"
        "SUPER+SHIFT,C,killclient,"
        "SUPER,M,togglefullscreen,"
        "SUPER,Space,togglefloating,"
        "SUPER,G,toggleglobal,"
        "SUPER,O,toggleoverview,"
        "SUPER,I,minimized,"
        "SUPER+SHIFT,I,restore_minimized"
        "SUPER+SHIFT,R,reload_config"
        "SUPER+ALT,N,switch_layout"

        "ALT,Tab,toggleoverview,"
        "ALT,backslash,togglefloating,"
        "ALT,a,togglemaximizescreen,"
        "ALT,f,togglefullscreen,"
        "ALT+SHIFT,f,togglefakefullscreen,"
        "ALT,z,toggle_scratchpad"
        "ALT,e,set_proportion,1.0"
        "ALT,x,switch_proportion_preset,"

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

        "SUPER+SHIFT,1,tag,1,0"
        "SUPER+SHIFT,2,tag,2,0"
        "SUPER+SHIFT,3,tag,3,0"
        "SUPER+SHIFT,4,tag,4,0"
        "SUPER+SHIFT,5,tag,5,0"
        "SUPER+SHIFT,6,tag,6,0"
        "SUPER+SHIFT,7,tag,7,0"
        "SUPER+SHIFT,8,tag,8,0"
        "SUPER+SHIFT,9,tag,9,0"

        "SUPER+CTRL,Left,focusmon,left"
        "SUPER+CTRL,Right,focusmon,right"
        "SUPER+CTRL,H,focusmon,left"
        "SUPER+CTRL,L,focusmon,right"
        "SUPER+ALT,Left,tagmon,left"
        "SUPER+ALT,Right,tagmon,right"

        "SUPER,equal,incgaps,1"
        "SUPER,minus,incgaps,-1"
        "SUPER+SHIFT,G,togglegaps"

        "CTRL+SHIFT,Up,movewin,+0,-50"
        "CTRL+SHIFT,Down,movewin,+0,+50"
        "CTRL+SHIFT,Left,movewin,-50,+0"
        "CTRL+SHIFT,Right,movewin,+50,+0"

        "CTRL+ALT,Up,resizewin,+0,-50"
        "CTRL+ALT,Down,resizewin,+0,+50"
        "CTRL+ALT,Left,resizewin,-50,+0"
        "CTRL+ALT,Right,resizewin,+50,+0"

        # grimblast ignores XDG_SCREENSHOTS_DIR — force the path so screenshots land in myconfig.constants.screenshots
        "NONE,Print,spawn,sh -c 'mkdir -p ${screenshotsDir} && cd ${screenshotsDir} && grimblast --notify --freeze copysave output'"
        "SUPER+CTRL,3,spawn,sh -c 'mkdir -p ${screenshotsDir} && cd ${screenshotsDir} && grimblast --notify --freeze copysave output'"
        "SUPER+CTRL,4,spawn,sh -c 'mkdir -p ${screenshotsDir} && cd ${screenshotsDir} && grimblast --notify --freeze copysave area'"
        "SUPER,BracketRight,spawn,brightnessctl s 10%+"
        "SUPER,BracketLeft,spawn,brightnessctl s 10%-"

        "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
        "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "NONE,XF86MonBrightnessUp,spawn,brightnessctl s 10%+"
        "NONE,XF86MonBrightnessDown,spawn,brightnessctl s 10%-"
        "NONE,XF86AudioNext,spawn,playerctl next"
        "NONE,XF86AudioPause,spawn,playerctl play-pause"
        "NONE,XF86AudioPlay,spawn,playerctl play-pause"
        "NONE,XF86AudioPrev,spawn,playerctl previous"
      ];

      baseMouseBinds = [
        "SUPER,btn_left,moveresize,curmove"
        "SUPER,btn_right,moveresize,curresize"
        "NONE,btn_middle,togglemaximizescreen,0"
      ];

      baseAxisBinds = [
        "SUPER,UP,viewtoleft_have_client"
        "SUPER,DOWN,viewtoright_have_client"
      ];

      tagRules = [
        "id:1,layout_name:scroller"
        "id:2,layout_name:scroller"
        "id:3,layout_name:scroller"
        "id:4,layout_name:scroller"
        "id:5,layout_name:scroller"
        "id:6,layout_name:scroller"
        "id:7,layout_name:scroller"
        "id:8,layout_name:scroller"
        "id:9,layout_name:scroller"
      ];

      baseLayerRules = [
        "animation_type_open:zoom,layer_name:rofi"
        "animation_type_close:zoom,layer_name:rofi"
        "animation_type_open:zoom,layer_name:walker"
        "animation_type_close:zoom,layer_name:walker"
      ];
    in
    {
      wayland.windowManager.mango.settings = {
        bind = baseBinds ++ cfg.extraBinds;
        mousebind = baseMouseBinds ++ cfg.extraMouseBinds;
        axisbind = baseAxisBinds ++ cfg.extraAxisBinds;
        tagrule = tagRules;
        layerrule = baseLayerRules ++ cfg.extraLayerRules;
      };
    };
}
