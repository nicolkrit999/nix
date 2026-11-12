{ lib }:
let
  inherit (lib.generators) mkLuaInline;
  cmdLib = import ./cmd.nix { inherit lib; };

  luaQ = s:
    let
      esc = builtins.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] s;
    in
    "\"${esc}\"";

  mkBind = { mods ? "", key, dispatcher, flags ? null }:
    let
      keyStr = if mods == "" then key else "${mods} + ${key}";
      base = [ keyStr (mkLuaInline dispatcher) ];
    in
    { _args = if flags == null then base else base ++ [ flags ]; };

  exec = cmd: "hl.dsp.exec_cmd(${luaQ cmd})";
  dspOf = v:
    let g = cmdLib.hyprGlobal v; in
    if g != null then "hl.dsp.global(${luaQ g})" else exec (cmdLib.asLine v);
  focusDir = d: "hl.dsp.focus({ direction = \"${d}\" })";
  swapDir = d: "hl.dsp.window.swap({ direction = \"${d}\" })";
  focusWs = ws: "hl.dsp.focus({ workspace = \"${ws}\" })";
  moveToWs = ws: "hl.dsp.window.move({ workspace = \"${ws}\" })";
  moveToWsSilent = ws: "hl.dsp.window.move({ workspace = \"${ws}\", follow = false })";
  resizeBy = x: y: "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
  focusMonitor = m: "hl.dsp.focus({ monitor = ${luaQ m} })";
  moveToMonitor = m: "hl.dsp.window.move({ monitor = ${luaQ m} })";

  repeatBind = { mods ? "", key, cmd }: mkBind {
    inherit mods key;
    dispatcher = exec (cmdLib.asLine cmd);
    flags = { locked = true; repeating = true; };
  };
  lockedBind = { key, cmd }: mkBind {
    inherit key;
    dispatcher = exec (cmdLib.asLine cmd);
    flags = { locked = true; };
  };

  present = lib.filter (b: b.cmd != null);
in
{ constants, shell }:
let
  mod = "SUPER";
  term = constants.terminal.name;
  inherit (constants) browser;
  rawFm = constants.fileManager;
  rawEd = constants.editor;
  termApps = constants.terminalApps;
  smartFm = if builtins.elem rawFm termApps then "${term} --class ${rawFm} -e ${rawFm}" else rawFm;
  smartEd = if builtins.elem rawEd termApps then "${term} --class ${rawEd} -e ${rawEd}" else rawEd;

  s = field: shell.${field} or null;
  optBind = field: mk: lib.optional (s field != null) (mk (s field));

  bindelList = map repeatBind (present [
    { key = "XF86AudioRaiseVolume"; cmd = s "volumeUp"; }
    { key = "XF86AudioLowerVolume"; cmd = s "volumeDown"; }
    { key = "XF86AudioMute"; cmd = s "volumeMute"; }
    { key = "XF86AudioMicMute"; cmd = s "micMute"; }
    { key = "XF86MonBrightnessUp"; cmd = s "brightnessUp"; }
    { key = "XF86MonBrightnessDown"; cmd = s "brightnessDown"; }
    { mods = mod; key = "bracketright"; cmd = s "brightnessUp"; }
    { mods = mod; key = "bracketleft"; cmd = s "brightnessDown"; }
    { key = "XF86KbdBrightnessUp"; cmd = s "kbdBrightnessUp"; }
    { key = "XF86KbdBrightnessDown"; cmd = s "kbdBrightnessDown"; }
  ]);

  bindlList = map lockedBind (present [
    { key = "XF86AudioNext"; cmd = s "mediaNext"; }
    { key = "XF86AudioPause"; cmd = s "mediaPlay"; }
    { key = "XF86AudioPlay"; cmd = s "mediaPlay"; }
    { key = "XF86AudioPrev"; cmd = s "mediaPrev"; }
    { key = "XF86AudioStop"; cmd = s "mediaStop"; }
    { key = "Caps_Lock"; cmd = s "capsLock"; }
  ]);

  helper = s "workspaceHelper";
  wsKey = n: if n == 0 then "10" else toString n;
  wsBind = n:
    if helper == null
    then mkBind { mods = mod; key = toString n; dispatcher = focusWs (wsKey n); }
    else mkBind { mods = mod; key = toString n; dispatcher = exec "${helper} focus ${wsKey n}"; };
  wsMoveBind = n:
    if helper == null
    then mkBind { mods = "${mod}+SHIFT"; key = toString n; dispatcher = moveToWsSilent (wsKey n); }
    else mkBind { mods = "${mod}+SHIFT"; key = toString n; dispatcher = exec "${helper} movesilent ${wsKey n}"; };
  wsFollowBind = n:
    if helper == null
    then mkBind { mods = "${mod}+ALT"; key = toString n; dispatcher = moveToWs (wsKey n); }
    else mkBind { mods = "${mod}+ALT"; key = toString n; dispatcher = exec "${helper} move ${wsKey n}"; };
in
lib.flatten [
  (mkBind { mods = "${mod}+SHIFT"; key = "C"; dispatcher = "hl.dsp.window.close()"; })
  (mkBind { mods = mod; key = "T"; dispatcher = ''hl.dsp.layout("togglesplit")''; })
  (mkBind { mods = mod; key = "space"; dispatcher = ''hl.dsp.window.float({ action = "toggle" })''; })
  (mkBind { mods = mod; key = "M"; dispatcher = "hl.dsp.window.fullscreen()"; })
  (mkBind { mods = "${mod}+ALT"; key = "P"; dispatcher = "hl.dsp.window.pin()"; })
  (mkBind { mods = mod; key = "P"; dispatcher = exec "hyprctl dispatch 'hl.dsp.window.float({ action = \"toggle\" })' && hyprctl dispatch 'hl.dsp.window.resize({ x = 800, y = 450, relative = false })' && hyprctl dispatch 'hl.dsp.window.pin()'"; })

  (optBind "launcher" (v: mkBind { mods = mod; key = "A"; dispatcher = dspOf v; }))
  (optBind "menu" (v: mkBind { mods = "${mod}+SHIFT"; key = "A"; dispatcher = exec (cmdLib.asLine v); }))
  (mkBind { mods = mod; key = "return"; dispatcher = exec term; })
  (mkBind { mods = mod; key = "F"; dispatcher = exec smartFm; })
  (mkBind { mods = mod; key = "B"; dispatcher = exec browser; })
  (mkBind { mods = mod; key = "C"; dispatcher = exec smartEd; })

  (mkBind { mods = "${mod}+SHIFT"; key = "Delete"; dispatcher = "hl.dsp.exit()"; })
  (mkBind { mods = mod; key = "Delete"; dispatcher = dspOf (s "lock"); })

  (optBind "emoji" (v: mkBind { mods = mod; key = "period"; dispatcher = exec (cmdLib.asLine v); }))
  (optBind "picker" (v: mkBind { mods = "${mod}+SHIFT"; key = "P"; dispatcher = exec (cmdLib.asLine v); }))
  (optBind "clipboard" (v: mkBind { mods = mod; key = "V"; dispatcher = dspOf v; }))
  (optBind "reload" (v: mkBind { mods = "${mod}+SHIFT"; key = "R"; dispatcher = exec (cmdLib.asLine v); }))
  (optBind "notifications" (v: mkBind { mods = mod; key = "N"; dispatcher = exec (cmdLib.asLine v); }))

  (optBind "barReload" (v: mkBind { mods = "${mod}+ALT"; key = "W"; dispatcher = exec (cmdLib.asLine v); }))
  (optBind "barToggle" (v: mkBind { mods = "${mod}+SHIFT"; key = "W"; dispatcher = exec (cmdLib.asLine v); }))

  (lib.optional ((s "printKey") != false && (s "screenshotScreen") != null) (mkBind { key = "Print"; dispatcher = exec (cmdLib.asLine (s "screenshotScreen")); }))
  (optBind "screenshotScreen" (v: mkBind { mods = "${mod}+CTRL"; key = "3"; dispatcher = exec (cmdLib.asLine v); }))
  (optBind "screenshotArea" (v: mkBind { mods = "${mod}+CTRL"; key = "4"; dispatcher = exec (cmdLib.asLine v); }))

  (mkBind { mods = mod; key = "left"; dispatcher = focusDir "left"; })
  (mkBind { mods = mod; key = "H"; dispatcher = focusDir "left"; })
  (mkBind { mods = mod; key = "right"; dispatcher = focusDir "right"; })
  (mkBind { mods = mod; key = "L"; dispatcher = focusDir "right"; })
  (mkBind { mods = mod; key = "up"; dispatcher = focusDir "up"; })
  (mkBind { mods = mod; key = "K"; dispatcher = focusDir "up"; })
  (mkBind { mods = mod; key = "down"; dispatcher = focusDir "down"; })
  (mkBind { mods = mod; key = "J"; dispatcher = focusDir "down"; })

  (mkBind { mods = "${mod}+SHIFT"; key = "left"; dispatcher = swapDir "left"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "H"; dispatcher = swapDir "left"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "right"; dispatcher = swapDir "right"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "L"; dispatcher = swapDir "right"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "up"; dispatcher = swapDir "up"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "K"; dispatcher = swapDir "up"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "down"; dispatcher = swapDir "down"; })
  (mkBind { mods = "${mod}+SHIFT"; key = "J"; dispatcher = swapDir "down"; })

  (mkBind { mods = "${mod}+CTRL"; key = "left"; dispatcher = resizeBy (-60) 0; })
  (mkBind { mods = "${mod}+CTRL"; key = "right"; dispatcher = resizeBy 60 0; })
  (mkBind { mods = "${mod}+CTRL"; key = "up"; dispatcher = resizeBy 0 (-60); })
  (mkBind { mods = "${mod}+CTRL"; key = "down"; dispatcher = resizeBy 0 60; })

  (mkBind { mods = mod; key = "S"; dispatcher = ''hl.dsp.workspace.toggle_special("magic")''; })
  (mkBind { mods = "${mod}+SHIFT"; key = "S"; dispatcher = moveToWs "special:magic"; })

  (mkBind { mods = "${mod}+CTRL"; key = "H"; dispatcher = focusMonitor "-1"; })
  (mkBind { mods = "${mod}+CTRL"; key = "L"; dispatcher = focusMonitor "+1"; })
  (mkBind { mods = "${mod}+ALT"; key = "H"; dispatcher = moveToMonitor "-1"; })
  (mkBind { mods = "${mod}+ALT"; key = "L"; dispatcher = moveToMonitor "+1"; })
]
++ (map wsBind [ 1 2 3 4 5 6 7 8 9 0 ])
++ (map wsMoveBind [ 1 2 3 4 5 6 7 8 9 0 ])
++ (map wsFollowBind [ 1 2 3 4 5 6 7 8 9 0 ])
++ [
  (mkBind { mods = mod; key = "mouse:272"; dispatcher = "hl.dsp.window.drag()"; flags = { mouse = true; }; })
  (mkBind { mods = mod; key = "mouse:273"; dispatcher = "hl.dsp.window.resize()"; flags = { mouse = true; }; })
]
++ bindelList
++ bindlList
