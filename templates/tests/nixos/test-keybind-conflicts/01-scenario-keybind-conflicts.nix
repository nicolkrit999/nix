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
    };

  niriChecks = c:
    let
      binds = (hmOf c).programs.niri.settings.binds;
      names = builtins.attrNames binds;
      normed = map plusNorm names;
      spawnOf = n: binds.${n}.action.spawn or null;
      badSpawn = lib.filter
        (n:
          let s = spawnOf n; in
          s != null && !(builtins.isList s && s != [ ] && lib.all (x: builtins.isString x && x != "") s))
        names;
    in
    {
      "niri-binds-present" = chk (builtins.length names > 50) "only ${toString (builtins.length names)} binds";
      "niri-binds-unique" = chk (dups normed == [ ]) "binds colliding after normalisation: ${lib.concatStringsSep ", " (dups normed)}";
      "niri-spawn-nonempty-strings" = chk (badSpawn == [ ]) "bad spawn lists: ${lib.concatStringsSep ", " badSpawn}";
    };

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
    in
    {
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
    // lib.optionalAttrs (enabled c "niri") (niriChecks c)
    // lib.optionalAttrs (enabled c "gnome") (gnomeChecks c)
    // lib.optionalAttrs (enabled c "kde") (kdeChecks c);

  gnomeScripts = lib.filterAttrs (_: v: v != "") (lib.mapAttrs
    (_name: c:
      if !(enabled c "gnome") then ""
      else
        let
          ds = (hmOf c).dconf.settings;
          shot = lib.filter (e: (e.binding or "") == "Print") (map (n: ds.${n}) (lib.filter (lib.hasPrefix gnomePrefix) (builtins.attrNames ds)));
        in
        if shot == [ ] then "" else builtins.readFile (lib.head shot).command)
    variants);
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
    "dups-ignores-unique" = chk (dups [ "a" "b" ] == [ ] && dups [ "a" "a" "b" ] == [ "a" ]) "dups helper broken";
  };
}
