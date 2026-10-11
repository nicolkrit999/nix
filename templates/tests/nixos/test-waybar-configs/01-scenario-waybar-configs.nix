let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hmOf = c: c.home-manager.users.krit;
  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;
  noMonitors = desktop.extendModules {
    modules = [{ myconfig.programs.mango.monitors = lib.mkForce [ ]; }];
  };

  variants = {
    nixos-desktop = desktop.config;
    nixos-laptop = laptop.config;
    desktop-mango-no-monitors = noMonitors.config;
  };

  has = lib.hasInfix;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  allOk = bad: msg: chk (bad == [ ]) "${msg}: ${lib.concatStringsSep ", " bad}";

  wms = [ "hyprland" "mango" "niri" ];
  cfgKey = wm: "waybar-${wm}/config";
  cssKey = wm: "waybar-${wm}/style.css";
  textOf = c: key: let f = (hmOf c).xdg.configFile; in if f ? ${key} then builtins.unsafeDiscardStringContext f.${key}.text else null;
  barsOf = c: wm:
    let t = textOf c (cfgKey wm);
    in if t == null then null else
    let j = builtins.fromJSON t; in if builtins.isList j then j else [ j ];
  svcOf = c: wm: (hmOf c).systemd.user.services."waybar-${wm}" or null;

  modulesOf = bar: lib.concatMap (k: bar.${k} or [ ]) [ "modules-left" "modules-center" "modules-right" ];
  undefinedModules = bar: lib.filter (m: !(bar ? ${m})) (modulesOf bar);

  shellKeys = [ "exec" "on-click" "on-click-right" "on-click-middle" ];
  snippetsOf = prefix: bars:
    lib.listToAttrs (lib.concatLists (lib.imap0
      (i: bar:
        lib.concatLists (lib.mapAttrsToList
          (m: v:
            if builtins.isAttrs v
            then
              lib.concatMap
                (k:
                  lib.optional (builtins.isString (v.${k} or null))
                    { name = "${prefix}/bar${toString i}/${m}.${k}"; value = v.${k}; })
                shellKeys
            else [ ])
          bar))
      bars));

  monitorNames = strs: map
    (s: lib.removeSuffix "$" (lib.removePrefix "^" (lib.removePrefix "name:" (lib.head (lib.splitString "," s)))))
    strs;

  colorLines = css: lib.filter builtins.isString (builtins.split "@define-color base0[0-9A-F] #[0-9a-fA-F]{6};" css);
  hexKeys = [ "00" "01" "02" "03" "04" "05" "06" "07" "08" "09" "0A" "0B" "0C" "0D" "0E" "0F" ];

  swayncOn = c: c.myconfig.services.swaync.enable or false;

  barCommon = c: wm: bars:
    let
      svc = svcOf c wm;
      css = textOf c (cssKey wm);
      colors = (hmOf c).lib.stylix.colors.withHashtag;
      missingColors = lib.filter (k: !(has "@define-color base${k} ${colors."base${k}"};" css)) hexKeys;
      exec = lib.toList svc.Service.ExecStart;
      bar0 = lib.head bars;
      notifPresent = lib.elem "custom/notification" bar0.modules-right;
    in
    {
      "${wm}: config is non-empty JSON" = chk (bars != [ ] && lib.all (b: b ? layer && b ? modules-right) bars) "no bar with layer/modules-right";
      "${wm}: every listed module is defined" = allOk (lib.concatMap undefinedModules bars) "undefined modules";
      "${wm}: custom/notification iff swaync enabled" = chk (notifPresent == swayncOn c && (!notifPresent || bar0 ? "custom/notification")) "notification module ${toString notifPresent} vs swaync ${toString (swayncOn c)}";
      "${wm}: style.css has 16 palette defines" = chk (lib.length (lib.filter (x: x != "") (colorLines css)) == 16 && missingColors == [ ]) "missing/mismatched palette: ${toString missingColors}";
      "${wm}: style.css has rules beyond the defines" = chk (lib.stringLength css > 1500) "style.css suspiciously short";
      "${wm}: ExecStart points at the generated config and css" = chk (svc != null && has "-c %h/.config/waybar-${wm}/config" (toString exec) && has "-s %h/.config/waybar-${wm}/style.css" (toString exec)) "ExecStart: ${toString exec}";
    };

  hyprlandChecks = c:
    let
      bars = barsOf c "hyprland";
      bar = lib.head bars;
      opts = c.myconfig.programs.waybar-hyprland;
      lang = bar."hyprland/language";
      svc = svcOf c "hyprland";
      icons = bar."hyprland/workspaces".format-icons;
      iconsMissing = lib.filter (k: (icons.${k} or null) != opts.waybarWorkspaceIcons.${k}) (builtins.attrNames opts.waybarWorkspaceIcons);
      layoutMissing = lib.filter (k: (lang.${k} or null) != opts.waybarLayout.${k}) (builtins.attrNames opts.waybarLayout);
    in
    barCommon c "hyprland" bars // {
      "hyprland: single bar" = chk (builtins.length bars == 1) "expected one bar, got ${toString (builtins.length bars)}";
      "hyprland: language on-click uses hyprctl switchxkblayout" = chk (has "hyprctl switchxkblayout " (lang.on-click or "")) "on-click: ${lang.on-click or "<none>"}";
      "hyprland: switchxkblayout targets the configured keyboard" =
        chk (lang.on-click == (if opts.keyboardName != "" then "hyprctl switchxkblayout ${opts.keyboardName} next" else "hyprctl switchxkblayout all next") && (opts.keyboardName == "" || (lang.keyboard-name or "") == opts.keyboardName)) "on-click ${lang.on-click}, keyboard-name ${lang.keyboard-name or "<none>"}, option ${opts.keyboardName}";
      "hyprland: no legacy hyprctl dispatch in config" = chk (!(has "hyprctl dispatch" (textOf c (cfgKey "hyprland")))) "config contains legacy hyprctl dispatch";
      "hyprland: waybarLayout override wins in hyprland/language" = chk (layoutMissing == [ ]) "not applied: ${toString layoutMissing}";
      "hyprland: waybarWorkspaceIcons reach format-icons" = chk (iconsMissing == [ ] && icons ? default) "icons missing: ${toString iconsMissing}";
      "hyprland: unit bound to hyprland-session.target" = chk (svc.Install.WantedBy == [ "hyprland-session.target" ] && svc.Unit.PartOf == [ "hyprland-session.target" ]) "WantedBy ${toString svc.Install.WantedBy}";
    };

  mangoChecks = c: monStrs:
    let
      bars = barsOf c "mango";
      names = monitorNames monStrs;
      outputs = map (b: b.output or null) bars;
      svc = svcOf c "mango";
      wrongPerMonitor = lib.concatMap
        (b:
          lib.filter (m: !(has "--arg mon \"${b.output}\"" (b.${m}.exec or ""))) [ "custom/tags" "custom/layout" "custom/window" ])
        (lib.filter (b: b ? output) bars);
      layoutSymbols = [ "S" "T" "M" "G" "K" "CT" "VT" "VS" "VG" "VK" "RT" "DW" "F" "VF" ];
      layoutExec = (lib.head bars)."custom/layout".exec;
      symbolsMissing = lib.filter (s: !(has "${s})" layoutExec)) layoutSymbols;
    in
    barCommon c "mango" bars // {
      "mango: bar count equals monitor count (>=1)" = chk (builtins.length bars == lib.max 1 (builtins.length names)) "${toString (builtins.length bars)} bars for ${toString (builtins.length names)} monitors";
      "mango: every monitor string parses to a name" = chk (lib.all (s: lib.hasPrefix "name:" s) monStrs && lib.all (n: n != "" && !(has "," n)) names) "unparseable monitor strings: ${toString monStrs}";
      "mango: bar outputs equal monitor names, in order" = chk (names == [ ] || outputs == names) "outputs ${toString outputs} vs monitors ${toString names}";
      "mango: bar outputs are distinct" = chk (lib.unique outputs == outputs) "duplicate outputs: ${toString outputs}";
      "mango: no monitors gives one bar without output" = chk (names != [ ] || (builtins.length bars == 1 && !((lib.head bars) ? output))) "bars: ${toString (builtins.length bars)}";
      "mango: per-monitor modules use their own monitor name" = allOk wrongPerMonitor "modules not bound to their output";
      "mango: fallback bar resolves the focused monitor at runtime" = chk (names != [ ] || has "select(.active == true) | .name" (lib.head bars)."custom/tags".exec) "fallback custom/tags lacks focused-monitor lookup";
      "mango: custom/layout case covers every layout symbol" = chk (symbolsMissing == [ ]) "missing: ${toString symbolsMissing}";
      "mango: unit bound to mango-session.target" = chk (svc.Install.WantedBy == [ "mango-session.target" ] && svc.Unit.PartOf == [ "mango-session.target" ]) "WantedBy ${toString svc.Install.WantedBy}";
    };

  niriChecks = c:
    let
      bars = barsOf c "niri";
      bar = lib.head bars;
      opts = c.myconfig.programs.waybar-niri;
      svc = svcOf c "niri";
      layoutMissing = lib.filter (k: (bar."niri/language".${k} or null) != opts.waybarLayout.${k}) (builtins.attrNames opts.waybarLayout);
    in
    barCommon c "niri" bars // {
      "niri: single bar" = chk (builtins.length bars == 1) "expected one bar, got ${toString (builtins.length bars)}";
      "niri: language on-click switches layout via niri msg" = chk (bar."niri/language".on-click == "niri msg action switch-layout-next") "on-click: ${bar."niri/language".on-click or "<none>"}";
      "niri: workspaces on-click is activate" = chk (bar."niri/workspaces".on-click == "activate") "on-click: ${bar."niri/workspaces".on-click or "<none>"}";
      "niri: waybarLayout override wins in niri/language" = chk (layoutMissing == [ ]) "not applied: ${toString layoutMissing}";
      "niri: unit bound to niri.service" = chk (svc.Install.WantedBy == [ "niri.service" ] && svc.Unit.PartOf == [ "niri.service" ] && svc.Unit.After == [ "niri.service" ]) "WantedBy ${toString svc.Install.WantedBy}";
    };

  sharedModules = [ "custom/weather" "custom/wifi" "custom/bluetooth" "custom/mic" "custom/notification" "pulseaudio" "battery" "clock" ];
  driftChecks = c:
    let
      hyp = lib.head (barsOf c "hyprland");
      niri = lib.head (barsOf c "niri");
      mango = lib.head (barsOf c "mango");
      mismatch = m: lib.filter (w: (w.bar.${m} or null) != (hyp.${m} or null)) [{ n = "niri"; bar = niri; } { n = "mango"; bar = mango; }];
    in
    lib.listToAttrs (map
      (m: { name = "drift: ${m} identical across hyprland/niri/mango"; value = chk (mismatch m == [ ]) "differs from hyprland copy in: ${lib.concatMapStringsSep "," (w: w.n) (mismatch m)}"; })
      sharedModules);

  perVariant = _name: c:
    let
      hasMango = c.myconfig.programs.mango.enable;
      mangoMons = c.myconfig.programs.mango.monitors;
    in
    hyprlandChecks c // niriChecks c
    // (if hasMango then mangoChecks c mangoMons // driftChecks c else { "mango: waybar absent when mango disabled" = chk (textOf c (cfgKey "mango") == null) "mango waybar config generated without mango"; });

  results = lib.mapAttrs perVariant variants;

  snippets = lib.foldl' (acc: v: acc // v) { } (lib.mapAttrsToList
    (name: c:
      lib.foldl' (a: wm: let b = barsOf c wm; in if b == null then a else a // snippetsOf "${name}/${wm}" b) { } wms)
    variants);

  jsonTexts = lib.foldl' (acc: v: acc // v) { } (lib.mapAttrsToList
    (name: c: lib.listToAttrs (lib.concatMap
      (wm: let t = textOf c (cfgKey wm); in lib.optional (t != null) { name = "${name}/${wm}"; value = t; })
      wms))
    variants);

  sample = [ "name:^DP-9$,width:1,height:1,refresh:60,x:0,y:0,scale:1" "name:eDP-1,width:1" ];
  control = {
    "monitor name parser strips anchors" = chk (monitorNames sample == [ "DP-9" "eDP-1" ]) "got ${toString (monitorNames sample)}";
    "undefined-module detector bites" = chk (undefinedModules { modules-left = [ "custom/x" ]; } == [ "custom/x" ]) "detector missed an undefined module";
    "undefined-module detector accepts complete bar" = chk (undefinedModules { modules-left = [ "custom/x" ]; "custom/x" = { }; } == [ ]) "detector flagged a complete bar";
    "snippet collector finds exec and on-click" = chk (lib.attrNames (snippetsOf "p" [{ "custom/a" = { exec = "x"; on-click = "y"; format = "z"; }; }]) == [ "p/bar0/custom/a.exec" "p/bar0/custom/a.on-click" ]) "collector mismatch";
    "variant without monitors has no mango monitors" = chk (noMonitors.config.myconfig.programs.mango.monitors == [ ] && desktop.config.myconfig.programs.mango.monitors != [ ]) "no-monitors variant not effective";
    "layout override fixture is non-empty" = chk (desktop.config.myconfig.programs.waybar-hyprland.waybarLayout != { } && desktop.config.myconfig.programs.waybar-niri.waybarLayout != { }) "waybarLayout empty on desktop, override check would be vacuous";
  };
in
{
  inherit results snippets control;
  json-texts = jsonTexts;
}
