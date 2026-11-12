{ lib }:
let
  cmdLib = import ./cmd.nix { inherit lib; };
  spawnLine = v: "${if cmdLib.isShell v then "spawn_shell" else "spawn"},${cmdLib.asLine v}";
in
{ constants, shell, pip ? null }:
let
  term = constants.terminal.name;
  inherit (constants) browser editor fileManager;
  termApps = constants.terminalApps;
  smartLaunch =
    app: if builtins.elem app termApps then "${term} --class ${app} -e ${app}" else app;

  s = field: shell.${field} or null;
  optLine = field: mk: lib.optional (s field != null) (mk (s field));
  present = lib.filter (b: b.cmd != null);

  mediaBinds =
    lib.optional (s "brightnessUp" != null) "SUPER,BracketRight,${spawnLine (s "brightnessUp")}"
    ++ lib.optional (s "brightnessDown" != null) "SUPER,BracketLeft,${spawnLine (s "brightnessDown")}"
    ++ map (b: "NONE,${b.key},${spawnLine b.cmd}") (present [
      { key = "XF86AudioRaiseVolume"; cmd = s "volumeUp"; }
      { key = "XF86AudioLowerVolume"; cmd = s "volumeDown"; }
      { key = "XF86AudioMute"; cmd = s "volumeMute"; }
      { key = "XF86AudioMicMute"; cmd = s "micMute"; }
      { key = "XF86MonBrightnessUp"; cmd = s "brightnessUp"; }
      { key = "XF86MonBrightnessDown"; cmd = s "brightnessDown"; }
      { key = "XF86KbdBrightnessUp"; cmd = s "kbdBrightnessUp"; }
      { key = "XF86KbdBrightnessDown"; cmd = s "kbdBrightnessDown"; }
      { key = "XF86AudioNext"; cmd = s "mediaNext"; }
      { key = "XF86AudioPrev"; cmd = s "mediaPrev"; }
      { key = "XF86AudioStop"; cmd = s "mediaStop"; }
      { key = "Caps_Lock"; cmd = s "capsLock"; }
    ]);

  mediaSymBinds = map (b: "NONE,${b.key},${spawnLine b.cmd}") (present [
    { key = "XF86AudioPause"; cmd = s "mediaPlay"; }
    { key = "XF86AudioPlay"; cmd = s "mediaPlay"; }
  ]);

  screenshotBinds =
    lib.optional ((s "printKey") != false && s "screenshotScreen" != null) "NONE,Print,${spawnLine (s "screenshotScreen")}"
    ++ optLine "screenshotScreen" (v: "SUPER+CTRL,3,${spawnLine v}")
    ++ optLine "screenshotArea" (v: "SUPER+CTRL,4,${spawnLine v}");

  launcherBinds =
    optLine "launcher" (v: "SUPER,A,${spawnLine v}")
    ++ optLine "emoji" (v: "SUPER,period,${spawnLine v}")
    ++ optLine "clipboard" (v: "SUPER,V,${spawnLine v}");

  baseBinds = [
    "SUPER,Return,spawn,${term}"
  ]
  ++ optLine "menu" (v: "SUPER+SHIFT,A,${spawnLine v}")
  ++ [
    "SUPER,B,spawn,${browser}"
    "SUPER,F,spawn,${smartLaunch fileManager}"
    "SUPER,C,spawn,${smartLaunch editor}"
  ]
  ++ optLine "picker" (v: "SUPER+SHIFT,P,${spawnLine v}")
  ++ optLine "notifications" (v: "SUPER,N,${spawnLine v}")
  ++ [
    "SUPER,Delete,${spawnLine (s "lock")}"
    "SUPER+SHIFT,Delete,quit,"
    "SUPER+SHIFT,C,killclient,"
    "SUPER,M,togglefullscreen,"
    "SUPER,Space,togglefloating,"
    "SUPER,G,toggleglobal,"
    "SUPER+ALT,P,toggleglobal,"
  ]
  ++ lib.optional (pip != null) "SUPER,P,spawn,${pip}"
  ++ [
    "SUPER,O,toggleoverview,"
    "SUPER,I,minimized,"
    "SUPER+SHIFT,I,restore_minimized"
  ]
  ++ (if s "reload" == null then [ "SUPER+SHIFT,R,reload_config" ] else [ "SUPER+SHIFT,R,${spawnLine (s "reload")}" ])
  ++ [
    "SUPER+ALT,N,switch_layout"
    "SUPER,T,dwindle_toggle_current_split"
    "SUPER+ALT,T,setlayout,tile"
    "SUPER,S,toggle_special_tag"
    "SUPER+SHIFT,S,tag_special_tag"
    "SUPER+ALT,S,setlayout,scroller"
  ]
  ++ optLine "barReload" (v: "SUPER+ALT,W,${spawnLine v}")
  ++ optLine "barToggle" (v: "SUPER+SHIFT,W,${spawnLine v}")
  ++ [
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
  ]
  ++ screenshotBinds;
in
{
  bind = baseBinds ++ launcherBinds;
  bindl = mediaBinds;
  bindsl = mediaSymBinds;
  mousebind = [
    "SUPER,btn_left,moveresize,curmove"
    "SUPER,btn_right,moveresize,curresize"
  ];
  axisbind = [
    "SUPER,UP,viewtoleft_have_client"
    "SUPER,DOWN,viewtoright_have_client"
  ];
  gesturebind = [
    "none,left,3,viewtoright_have_client"
    "none,right,3,viewtoleft_have_client"
    "none,up,3,togglefullscreen"
    "none,down,3,killclient"
    "none,left,4,viewtoright_have_client"
    "none,right,4,viewtoleft_have_client"
    "none,down,4,toggle_special_tag"
  ]
  ++ optLine "launcher" (v: "none,up,4,${spawnLine v}");
}
