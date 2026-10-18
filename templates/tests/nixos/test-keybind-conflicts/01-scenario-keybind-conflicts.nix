let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostNames = [ "nixos-desktop" "nixos-laptop" ];
  hmOf = c: c.home-manager.users.krit;
  enabled = c: n: c.myconfig.programs.${n}.enable or false;

  variants = lib.listToAttrs (lib.concatMap
    (h:
      let c = flake.nixosConfigurations.${h}.config; in
      [{ name = h; value = c; }]
      ++ map
        (n: { name = "${h}+${n}"; value = c.specialisation.${n}.configuration; })
        (builtins.attrNames c.specialisation))
    hostNames);

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  dups = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);
  norm = mods: key: lib.concatStringsSep "+" (lib.sort (a: b: a < b) (map lib.toLower mods) ++ [ (lib.toLower key) ]);

  unwrap1 = v: if builtins.isAttrs v && (v._type or "") == "gvariant" then v.value else v;
  unwrap = v: let u = unwrap1 v; in if builtins.isList u then map unwrap1 u else u;

  plusSplit = s:
    let p = lib.splitString "+" s; in
    { mods = lib.init p; key = lib.last p; };

  canonMod = m:
    let l = lib.toLower m; in
    if lib.elem l [ "mod" "meta" "win" ] then "super" else if l == "primary" then "ctrl" else l;

  hyprNorm = s:
    let p = lib.splitString " + " s; in
    if builtins.length p == 1 then norm [ ] s
    else norm (map canonMod (lib.splitString "+" (lib.head p))) (lib.concatStringsSep " + " (lib.tail p));

  plusNorm = s: let p = plusSplit s; in norm (map canonMod p.mods) p.key;

  gnomeNorm = s:
    let
      m = builtins.match "((<[^>]+>)*)(.*)" s;
      modStr = builtins.elemAt m 0;
      key = builtins.elemAt m 2;
      mods = map (x: builtins.head x) (builtins.filter builtins.isList (builtins.split "<([^>]+)>" modStr));
    in
    norm (map canonMod mods) key;

  hyprChecks = c:
    let
      binds = (hmOf c).wayland.windowManager.hyprland.settings.bind;
      args = map (b: b._args) binds;
      keys = map (a: builtins.head a) args;
      normed = map hyprNorm keys;
      luaExpr = a: (builtins.elemAt a 1).expr or "";
      find = k: lib.filter (a: hyprNorm (builtins.head a) == k) args;
      wsOk = mods: wsPrefix: n:
        let
          k = norm (map canonMod mods) (toString n);
          ws = if n == 0 then "10" else toString n;
          hit = find k;
        in
        builtins.length hit == 1 && lib.hasInfix "${wsPrefix}workspace = \"${ws}\"" (luaExpr (lib.head hit));
      nums = lib.range 0 9;
      wsFail = mods: pfx: lib.filter (n: !(wsOk mods pfx n)) nums;
      focusF = wsFail [ "SUPER" ] "hl.dsp.focus({ ";
      moveF = wsFail [ "SUPER" "SHIFT" ] "hl.dsp.window.move({ ";
      followF = wsFail [ "SUPER" "ALT" ] "hl.dsp.window.move({ ";
    in
    {
      "hyprland-binds-present" = chk (builtins.length binds > 50) "only ${toString (builtins.length binds)} binds";
      "hyprland-binds-shape" = chk (lib.all (a: builtins.length a >= 2 && lib.hasPrefix "hl.dsp." (luaExpr a)) args) "bind without a key/hl.dsp dispatcher pair";
      "hyprland-binds-unique" = chk (dups normed == [ ]) "duplicate (mods,key): ${lib.concatStringsSep ", " (dups normed)}";
      "hyprland-ws-focus-1-to-0" = chk (focusF == [ ]) "SUPER+N missing or wrong workspace for N in ${toString focusF}";
      "hyprland-ws-move-1-to-0" = chk (moveF == [ ]) "SUPER+SHIFT+N missing or wrong workspace for N in ${toString moveF}";
      "hyprland-ws-follow-1-to-0" = chk (followF == [ ]) "SUPER+ALT+N missing or wrong workspace for N in ${toString followF}";
    } // waybarBindChecks "hyprland" (hyprWaybarCmds args);

  inherit (lib) upperChars;
  kebab = n: lib.removePrefix "-" (builtins.replaceStrings upperChars (map (u: "-" + lib.toLower u) upperChars) n);
  enumVariants = { text, honourSkip }:
    let
      body = lib.head (lib.splitString "\n}\n" (lib.elemAt (lib.splitString "\npub enum Action {\n" text) 1));
      step = acc: l:
        let m = builtins.match "    ([A-Z][A-Za-z0-9]*)([ ({,].*)?" l; in
        if honourSkip && l == "    #[knuffel(skip)]" then acc // { skip = true; }
        else if m != null then { skip = false; names = acc.names ++ lib.optional (!acc.skip) (kebab (lib.head m)); }
        else acc;
    in
    (lib.foldl' step { skip = false; names = [ ]; } (lib.splitString "\n" body)).names;

  niriActionSets = c:
    let src = (hmOf c).programs.niri.package.src; in
    {
      bindable = enumVariants { text = builtins.readFile "${src}/niri-config/src/binds.rs"; honourSkip = true; };
      ipc = enumVariants { text = builtins.readFile "${src}/niri-ipc/src/lib.rs"; honourSkip = false; };
    };

  msgActionsIn = text: lib.concatMap (m: m) (lib.filter builtins.isList (builtins.split "niri msg action ([a-z0-9-]+)" text));

  lockedMediaKeys = [
    "XF86AudioRaiseVolume"
    "XF86AudioLowerVolume"
    "XF86AudioMute"
    "XF86AudioMicMute"
    "XF86MonBrightnessUp"
    "XF86MonBrightnessDown"
    "XF86KbdBrightnessUp"
    "XF86KbdBrightnessDown"
  ];
  unlockedMediaKeys = [ "XF86AudioPlay" "XF86AudioPause" "XF86AudioNext" "XF86AudioPrev" "XF86AudioStop" "Mod+Delete" ];

  niriBindChecks = { binds, startup, actions }:
    let
      names = builtins.attrNames binds;
      normed = map plusNorm names;
      spawnOf = n: binds.${n}.action.spawn or null;
      badSpawn = lib.filter
        (n:
          let s = spawnOf n; in
          s != null && !(builtins.isList s && s != [ ] && lib.all (x: builtins.isString x && x != "") s))
        names;
      actionNamesOf = n: let a = binds.${n}.action or null; in if builtins.isAttrs a then builtins.attrNames a else [ "<not-an-action-node>" ];
      textOf = n:
        let b = binds.${n}.action; in
        lib.concatStringsSep " " ((if builtins.isList (b.spawn or null) then b.spawn else [ ]) ++ lib.optional (builtins.isString (b."spawn-sh" or null)) b."spawn-sh");
      unbindable = lib.filter (n: !(lib.all (a: lib.elem a actions.bindable) (actionNamesOf n))) names;
      msgTexts = map textOf (lib.filter (n: builtins.isAttrs (binds.${n}.action or null)) names) ++ map (lib.concatStringsSep " ") startup;
      unknownMsg = lib.filter (a: !(lib.elem a actions.ipc)) (lib.concatMap msgActionsIn msgTexts);
      reloadKey = "Mod+Shift+R";
      reloadNames = actionNamesOf reloadKey;
      reloadText = textOf reloadKey;
      lockedNow = lib.filter (n: binds.${n}.allow-when-locked or false == true) names;
      sorted = lib.sort (a: b: a < b);
    in
    {
      "niri-binds-present" = chk (builtins.length names > 50) "only ${toString (builtins.length names)} binds";
      "niri-binds-unique" = chk (dups normed == [ ]) "binds colliding after normalisation: ${lib.concatStringsSep ", " (dups normed)}";
      "niri-spawn-nonempty-strings" = chk (badSpawn == [ ]) "bad spawn lists: ${lib.concatStringsSep ", " badSpawn}";
      "niri-bind-actions-bindable" = chk (unbindable == [ ]) "binds whose action node niri rejects in config.kdl (IPC-only or unknown): ${lib.concatStringsSep ", " (map (n: "${n}=${lib.concatStringsSep "/" (actionNamesOf n)}") unbindable)}";
      "niri-msg-actions-exist" = chk (unknownMsg == [ ]) "`niri msg action X` with unknown X: ${lib.concatStringsSep ", " unknownMsg}";
      "niri-reload-bind-is-load-config-file" = chk
        (binds ? ${reloadKey}
          && !(lib.elem "reload-config" (reloadNames ++ msgActionsIn reloadText))
          && (lib.elem "load-config-file" (reloadNames ++ msgActionsIn reloadText)))
        "${reloadKey} is missing or not load-config-file (actions: ${lib.concatStringsSep "/" reloadNames}, text: ${reloadText})";
      "niri-media-keys-allow-when-locked" = chk
        (lib.all (k: binds ? ${k}) (lockedMediaKeys ++ unlockedMediaKeys) && sorted lockedNow == sorted lockedMediaKeys)
        "allow-when-locked set is [${lib.concatStringsSep " " (sorted lockedNow)}], expected exactly the 8 volume/mic/brightness keys";
    };

  niriChecks = c:
    niriBindChecks {
      binds = (hmOf c).programs.niri.settings.binds;
      startup = map (s: s.command) (hmOf c).programs.niri.settings.spawn-at-startup;
      actions = niriActionSets c;
    };

  waybarCmdOk = sig: cmd:
    let toks = lib.filter (t: t != "") (lib.splitString " " cmd); in
    toks != [ ] && lib.head toks == "pkill" && lib.last toks == "waybar" && lib.elem sig toks
    && !(lib.any (t: builtins.match "-[a-zA-Z]*x[a-zA-Z]*" t != null || t == "--exact") toks);

  waybarBindChecks = prefix: cmdOf:
    let
      one = key: sig:
        let cmds = cmdOf key; in
        chk (builtins.length cmds == 1 && waybarCmdOk sig (lib.head cmds))
          "${key}: expected one bind running `pkill ${sig} waybar` without -x, got [${lib.concatStringsSep " | " cmds}]";
    in
    {
      "${prefix}-waybar-toggle-bind" = one "toggle" "-SIGUSR1";
      "${prefix}-waybar-reload-bind" = one "reload" "-SIGUSR2";
    };

  hyprWaybarCmds = args: key:
    let
      k = if key == "toggle" then norm [ "super" "shift" ] "w" else norm [ "super" "alt" ] "w";
      hit = lib.filter (a: hyprNorm (builtins.head a) == k) args;
    in
    map (a: let m = builtins.match ".*exec_cmd\\(\"(.*)\"\\).*" ((builtins.elemAt a 1).expr or ""); in if m == null then "" else lib.head m) hit;

  mangoWaybarCmds = binds: key:
    let pfx = if key == "toggle" then "SUPER+SHIFT,W,spawn," else "SUPER+ALT,W,spawn,"; in
    map (lib.removePrefix pfx) (lib.filter (lib.hasPrefix pfx) binds);

  mangoChecks = c: waybarBindChecks "mango" (mangoWaybarCmds (hmOf c).wayland.windowManager.mango.settings.bind);

  gnomePrefix = "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom";
  gnomeChecks = c:
    let
      ds = (hmOf c).dconf.settings;
      mk = ds."org/gnome/settings-daemon/plugins/media-keys";
      customNames = lib.filter (lib.hasPrefix gnomePrefix) (builtins.attrNames ds);
      listed = unwrap mk.custom-keybindings;
      expectedList = map (n: "/${n}/") customNames;
      entries = map (n: ds.${n}) customNames;
      bindings = map (e: e.binding) entries;
      listBindings = sec: lib.concatLists (lib.filter builtins.isList (map unwrap (lib.attrValues (ds.${sec} or { }))));
      others = lib.concatMap listBindings [
        "org/gnome/desktop/wm/keybindings"
        "org/gnome/shell/keybindings"
      ] ++ unwrap (mk.screensaver or [ ]) ++ unwrap (mk.logout or [ ]);
      allNormed = map gnomeNorm (bindings ++ others);
      wm = ds."org/gnome/desktop/wm/keybindings";
      declared = c.myconfig.programs.gnome.wmKeybindings;
      mergeBad = lib.filter (k: if k == "close" then !(lib.all (a: lib.elem a (unwrap wm.close)) declared.close) else unwrap (wm.${k} or null) != declared.${k}) (lib.attrNames declared);
    in
    {
      "gnome-wm-keybindings-merged" = chk (lib.elem "<Super><Shift>c" (unwrap wm.close) && mergeBad == [ ]) "wm/keybindings lost the module close binding or a declared wmKeybindings key (bad: ${toString mergeBad})";
      "gnome-thumb-gestures-mapped" = chk (!(declared ? minimize) || (lib.elem "XF86Launch7" declared.minimize && !(declared ? close && lib.elem "XF86Launch7" declared.close) && lib.elem "XF86Launch7" (unwrap wm.minimize) && !(lib.elem "XF86Launch7" (unwrap wm.close)) && lib.elem "<Super>m" (unwrap wm.toggle-maximized) && lib.elem "<Super><Shift>c" (unwrap wm.close))) "thumb-gesture mapping broken: minimize must hold XF86Launch7, close must not, toggle-maximized must hold <Super>m";
      "gnome-message-tray-frees-super-m" = chk (!(lib.elem "<Super>m" (unwrap ds."org/gnome/shell/keybindings".toggle-message-tray))) "toggle-message-tray still holds <Super>m";
      "gnome-custom-entries-present" = chk (customNames != [ ]) "no custom<i> entries";
      "gnome-custom-list-matches-entries" = chk (builtins.length listed == builtins.length customNames && lib.sort (a: b: a < b) listed == lib.sort (a: b: a < b) expectedList) "custom-keybindings list (${toString (builtins.length listed)}) != custom<i> entries (${toString (builtins.length customNames)})";
      "gnome-entries-complete" = chk (lib.all (e: lib.all (f: (e.${f} or "") != "") [ "name" "command" "binding" ]) entries) "entry missing name/command/binding";
      "gnome-custom-bindings-unique" = chk (dups (map gnomeNorm bindings) == [ ]) "duplicate bindings: ${lib.concatStringsSep ", " (dups (map gnomeNorm bindings))}";
      "gnome-all-bindings-unique" = chk (dups allNormed == [ ]) "custom/wm/shell/screensaver/logout collide: ${lib.concatStringsSep ", " (dups allNormed)}";
      "gnome-native-screenshot-key-freed" = chk (unwrap (mk.screenshot or null) == [ ]) "media-keys.screenshot is not []";
      "gnome-native-screenshot-custom-print" = chk (lib.any (e: e.binding == "Print") entries) "no custom Print binding for the screenshot script";
    };

  kdeChecks = c:
    let
      hm = hmOf c;
      cmds = hm.programs.plasma.hotkeys.commands;
      keysOf = v: lib.toList (v.key or [ ]);
      cmdKeys = lib.concatMap keysOf (lib.attrValues cmds);
      shortcutVals = lib.concatMap
        (sec: lib.concatMap (v: lib.filter (s: s != "none" && s != "") (lib.toList v)) (lib.attrValues sec))
        (lib.attrValues hm.programs.plasma.shortcuts);
      cmdNormed = map plusNorm cmdKeys;
      scNormed = map plusNorm shortcutVals;
      collide = lib.filter (k: lib.elem k scNormed) cmdNormed;
    in
    {
      "kde-hotkeys-present" = chk (builtins.length cmdKeys > 5) "only ${toString (builtins.length cmdKeys)} hotkeys";
      "kde-hotkeys-all-have-key" = chk (lib.all (n: keysOf cmds.${n} != [ ]) (builtins.attrNames cmds)) "hotkey command without key";
      "kde-hotkeys-unique" = chk (dups cmdNormed == [ ]) "duplicate hotkeys: ${lib.concatStringsSep ", " (dups cmdNormed)}";
      "kde-hotkeys-vs-shortcuts" = chk (collide == [ ]) "hotkeys colliding with plasma.shortcuts: ${lib.concatStringsSep ", " collide}";
    };

  perVariant = _name: c:
    lib.optionalAttrs (enabled c "hyprland") (hyprChecks c)
    // lib.optionalAttrs (enabled c "mango") (mangoChecks c)
    // lib.optionalAttrs (enabled c "niri") (niriChecks c)
    // lib.optionalAttrs (enabled c "gnome") (gnomeChecks c)
    // lib.optionalAttrs (enabled c "kde") (kdeChecks c);

  readDrv = d: builtins.readFile (builtins.appendContext d { ${d} = { path = true; }; });
  scriptTextOf = cmd:
    let
      drv = readDrv (lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext cmd))));
      esc = lib.head (lib.splitString "\"),(\"out\"" (lib.elemAt (lib.splitString "(\"__json\",\"" drv) 1));
      json = builtins.replaceStrings [ "\\\\" "\\\"" "\\n" "\\t" "\\r" ] [ "\\" "\"" "\n" "\t" "\r" ] esc;
    in
    (builtins.fromJSON (builtins.unsafeDiscardStringContext json)).text;

  gnomeScripts = lib.filterAttrs (_: v: v != "") (lib.mapAttrs
    (_name: c:
      if !(enabled c "gnome") then ""
      else
        let
          ds = (hmOf c).dconf.settings;
          shot = lib.filter (e: (e.binding or "") == "Print") (map (n: ds.${n}) (lib.filter (lib.hasPrefix gnomePrefix) (builtins.attrNames ds)));
        in
        if shot == [ ] then "" else scriptTextOf (lib.head shot).command)
    variants);
  isFail = lib.hasPrefix "FAIL";
  laptop = variants."nixos-laptop";
  realNiri = {
    binds = (hmOf laptop).programs.niri.settings.binds;
    startup = map (s: s.command) (hmOf laptop).programs.niri.settings.spawn-at-startup;
    actions = niriActionSets laptop;
  };
  niriMut = f: niriBindChecks (realNiri // { binds = f realNiri.binds; });
  realMangoBinds = (hmOf variants."nixos-desktop").wayland.windowManager.mango.settings.bind;
  realHyprArgs = map (b: b._args) (hmOf laptop).wayland.windowManager.hyprland.settings.bind;
in
{
  results = lib.filterAttrs (_: v: v != { }) (lib.mapAttrs perVariant variants);

  gnome-scripts = gnomeScripts;

  control = {
    "hypr-detects-order-and-case" = chk (dups (map hyprNorm [ "SUPER+SHIFT + C" "shift+super + c" "SUPER + C" ]) != [ ]) "hyprNorm misses a reordered/case-variant duplicate";
    "hypr-distinguishes-different-mods" = chk (dups (map hyprNorm [ "SUPER+SHIFT + C" "SUPER + C" "SUPER+ALT + C" ]) == [ ]) "hyprNorm flags distinct binds";
    "niri-detects-mod-alias" = chk (dups (map plusNorm [ "Mod+Shift+A" "Super+SHIFT+a" ]) != [ ]) "plusNorm misses Mod/Super alias";
    "gnome-detects-order-and-case" = chk (dups (map gnomeNorm [ "<Super><Shift>c" "<Shift><Super>C" ]) != [ ]) "gnomeNorm misses reordered duplicate";
    "gnome-distinguishes-plain-key" = chk (dups (map gnomeNorm [ "<Super>c" "<Super><Shift>c" "Print" ]) == [ ]) "gnomeNorm flags distinct bindings";
    "kde-detects-hotkey-vs-shortcut" =
      let
        sc = [ "Meta+Ctrl+7" ];
        cm = [ "meta+ctrl+7" "Meta+A" ];
      in
      chk (lib.filter (k: lib.elem k (map plusNorm sc)) (map plusNorm cm) != [ ]) "kde collision matcher misses a case-variant collision";
    "niri-action-lists-parsed" =
      let a = niriActionSets laptop; in
      chk (lib.elem "close-window" a.bindable && lib.elem "spawn" a.bindable && !(lib.elem "load-config-file" a.bindable) && lib.elem "load-config-file" a.ipc && lib.elem "focus-column-first" a.ipc && !(lib.elem "reload-config" a.ipc) && builtins.length a.bindable > 100)
        "niri action lists wrong: bindable ${toString (builtins.length a.bindable)}, ipc ${toString (builtins.length a.ipc)}";
    "niri-mutation-reload-config-spawn-fails" =
      let r = niriMut (b: b // { "Mod+Shift+R".action.spawn = [ "niri" "msg" "action" "reload-config" ]; }); in
      chk (isFail r."niri-msg-actions-exist" && isFail r."niri-reload-bind-is-load-config-file") "reload-config spawn not flagged";
    "niri-mutation-load-config-file-spawn-passes" =
      let r = niriMut (b: b // { "Mod+Shift+R".action.spawn = [ "niri" "msg" "action" "load-config-file" ]; }); in
      chk (r."niri-msg-actions-exist" == "ok" && r."niri-bind-actions-bindable" == "ok" && r."niri-reload-bind-is-load-config-file" == "ok") "valid load-config-file spawn rejected";
    "niri-mutation-bare-ipc-action-node-fails" =
      let r = niriMut (b: b // { "Mod+Shift+R".action.load-config-file = [ ]; }); in
      chk (isFail r."niri-bind-actions-bindable") "IPC-only action node not flagged";
    "niri-mutation-unknown-action-node-fails" =
      let r = niriMut (b: b // { "Mod+Shift+R".action.reload-config = [ ]; }); in
      chk (isFail r."niri-bind-actions-bindable" && isFail r."niri-reload-bind-is-load-config-file") "unknown action node not flagged";
    "niri-mutation-startup-bogus-action-fails" =
      let r = niriBindChecks (realNiri // { startup = realNiri.startup ++ [ [ "bash" "-c" "sleep 1 && niri msg action no-such-action" ] ]; }); in
      chk (isFail r."niri-msg-actions-exist") "bogus niri msg action in spawn-at-startup not flagged";
    "niri-mutation-unlocked-media-key-fails" =
      let r = niriMut (b: b // { XF86AudioMute = removeAttrs b.XF86AudioMute [ "allow-when-locked" ]; }); in
      chk (isFail r."niri-media-keys-allow-when-locked") "media key without allow-when-locked not flagged";
    "niri-mutation-locked-playback-key-fails" =
      let r = niriMut (b: b // { XF86AudioPlay = b.XF86AudioPlay // { allow-when-locked = true; }; }); in
      chk (isFail r."niri-media-keys-allow-when-locked") "allow-when-locked on a playback key not flagged";
    "niri-mutation-missing-media-key-fails" =
      let r = niriMut (b: removeAttrs b [ "XF86AudioPlay" ]); in
      chk (isFail r."niri-media-keys-allow-when-locked") "vanished playback key not flagged";
    "waybar-cmd-matcher" =
      chk
        (waybarCmdOk "-SIGUSR1" "pkill -SIGUSR1 waybar"
          && !(waybarCmdOk "-SIGUSR1" "pkill -x -SIGUSR1 waybar")
          && !(waybarCmdOk "-SIGUSR1" "pkill -SIGUSR1 -fx waybar")
          && !(waybarCmdOk "-SIGUSR1" "pkill --exact -SIGUSR1 waybar")
          && !(waybarCmdOk "-SIGUSR1" "pkill -SIGUSR1 .waybar-wrapped")
          && !(waybarCmdOk "-SIGUSR1" "killall -SIGUSR1 waybar")
          && !(waybarCmdOk "-SIGUSR1" "pkill -SIGUSR2 waybar"))
        "waybarCmdOk accepts/rejects the wrong commands";
    "waybar-mutation-mango-x-flag-fails" =
      let r = waybarBindChecks "mango" (mangoWaybarCmds (map (builtins.replaceStrings [ "pkill -SIGUSR1" ] [ "pkill -x -SIGUSR1" ]) realMangoBinds)); in
      chk (isFail r."mango-waybar-toggle-bind" && r."mango-waybar-reload-bind" == "ok") "-x on the mango toggle bind not flagged (or reload bind affected)";
    "waybar-mutation-mango-missing-bind-fails" =
      let r = waybarBindChecks "mango" (mangoWaybarCmds (lib.filter (b: !(lib.hasPrefix "SUPER+ALT,W," b)) realMangoBinds)); in
      chk (isFail r."mango-waybar-reload-bind") "removed mango reload bind not flagged";
    "waybar-mutation-hyprland-x-flag-fails" =
      let
        mutate = a:
          if builtins.length a >= 2 && builtins.isAttrs (builtins.elemAt a 1)
          then [ (builtins.head a) ((builtins.elemAt a 1) // { expr = builtins.replaceStrings [ "pkill -SIGUSR1" ] [ "pkill -x -SIGUSR1" ] ((builtins.elemAt a 1).expr or ""); }) ]
          else a;
        r = waybarBindChecks "hyprland" (hyprWaybarCmds (map mutate realHyprArgs));
      in
      chk (isFail r."hyprland-waybar-toggle-bind" && r."hyprland-waybar-reload-bind" == "ok") "-x on the hyprland toggle bind not flagged (or reload bind affected)";
    "dups-ignores-unique" = chk (dups [ "a" "b" ] == [ ] && dups [ "a" "a" "b" ] == [ "a" ]) "dups helper broken";
  };
}
