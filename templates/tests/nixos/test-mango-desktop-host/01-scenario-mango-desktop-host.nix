let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostCfg = flake.nixosConfigurations.nixos-desktop.config;
  hm = hostCfg.home-manager.users.krit;
  mangoOpts = hostCfg.myconfig.programs.mango;
  s = hm.wayland.windowManager.mango.settings;
  idle = hm.services.hypridle.settings;

  bind = s.bind or [ ];
  bindl = s.bindl or [ ];
  bindsl = s.bindsl or [ ];
  windowRule = s.window_rule or [ ];

  has = infix: str: lib.hasInfix infix str;
  anyHas = infix: list: lib.any (has infix) list;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  combo = b: lib.concatStringsSep "," (lib.take 2 (lib.splitString "," b));

  keyLists = lib.genAttrs [ "bind" "bindl" "bindsl" "mousebind" "axisbind" "gesturebind" "tag_rule" "layer_rule" ] (k: s.${k} or [ ]);
  fieldCount = str: lib.length (lib.splitString "," str);
  isRuleList = k: k == "tag_rule" || k == "layer_rule";
  minFields = k: if isRuleList k then 2 else 3;
  badField = k: v: fieldCount v < minFields k || (isRuleList k && lib.any (f: builtins.match "[a-z_]+:.+" f == null) (lib.splitString "," v));
  shortKeys = lib.concatLists (lib.mapAttrsToList (k: l: map (v: "${k}: ${v}") (lib.filter (badField k) l)) keyLists);

  tagRule = s.tag_rule or [ ];
  layoutOf = name: id: lib.filter (r: has "id:${toString id}," r && has "monitor_name:^${name}$," r) tagRule;
  layoutsOpt = mangoOpts.monitorLayouts;
  tagIds = lib.range 1 9;
  perMonitorOk = rules: layouts: lib.all
    (name: lib.all
      (id: lib.elem "id:${toString id},monitor_name:^${name}$,layout_name:${layouts.${name}}" rules)
      tagIds)
    (builtins.attrNames layouts);
  tagRuleSyntaxOk = r: builtins.match "id:[0-9]+,(monitor_name:[^,]+,)?layout_name:[a-z_]+" r != null;

  sessionVars = hm.home.sessionVariables;
  sysdVars = hm.wayland.windowManager.mango.systemd.variables;
  sysdAllow = [ "DISPLAY" "WAYLAND_DISPLAY" "XDG_CURRENT_DESKTOP" "XDG_SESSION_TYPE" "XDG_SESSION_DESKTOP" "XCURSOR_THEME" "XCURSOR_SIZE" ];
  sysdUndefined = lib.filter (v: !(sessionVars ? ${v}) && !(lib.elem v sysdAllow)) sysdVars;
  firstMonitor = lib.head mangoOpts.monitors;
  firstScale = builtins.match ".*scale:([0-9]+(\\.[0-9]+)?).*" firstMonitor;

  hasTag0Rule = rules: cls: lib.any (r: has "tags:0," r && has "app_id:^${cls}$" r) rules;
  dupCombos = l: let all = map combo l; in lib.filter (c: lib.length (lib.filter (x: x == c) all) > 1) (lib.unique all);
  emptyPreset = b: lib.hasSuffix "switch_proportion_preset," b;
  zeroOpacity = r: builtins.match ".*opacity:0(,.*)?" r != null;
  runsDpms = arg: str: lib.any (l: builtins.match ".*/bin/mango-dpms ${arg}([^a-z].*)?" l != null) (lib.splitString "\n" str);
  noDirectWlopm = strs: !(lib.any (has "wlopm") strs);

  listeners = idle.listener;
  screenOff = lib.findFirst (l: has "wlopm" (l.on-timeout or "") || has "mango-dpms" (l.on-timeout or "")) null listeners;
  hypridleStrings = [ idle.general.after_sleep_cmd ] ++ lib.concatMap (l: [ (l.on-timeout or "") (l.on-resume or "") ]) listeners;
in
{
  check-scratch-binds-have-tag0-rules =
    let
      scratch = lib.filter (b: has "/bin/mango-scratch " b) bind;
      classes = lib.concatMap (b: map (m: lib.head m) (lib.filter (m: m != null) (map (builtins.match ".*--class ([a-z-]+).*") [ b ]))) scratch;
      missing = lib.filter (c: !(hasTag0Rule windowRule c)) classes;
    in
    chk (classes != [ ] && missing == [ ]) "mango-scratch classes without a tags:0 window rule (classes: ${toString classes}, missing: ${toString missing})";
  check-scratch-rule-control =
    chk (hasTag0Rule [ "is_floating:1,tags:0,app_id:^a$" ] "a" && !(hasTag0Rule [ "is_floating:1,tags:0,app_id:^b$" ] "a") && !(hasTag0Rule [ "is_floating:1,app_id:^a$" ] "a")) "tag0 predicate does not discriminate";
  check-no-window-rule-once = chk ((s.window_rule_once or [ ]) == [ ]) "window_rule_once is not empty";
  check-no-plain-exec = chk (!(s ? exec) || s.exec == [ ]) "plain exec entries present (use exec_once)";
  check-media-keys-not-in-bind =
    let anywhere = bindl ++ bindsl; in
    chk (anyHas "XF86AudioPlay" anywhere && anyHas "XF86AudioPause" anywhere && !(anyHas "XF86AudioPlay" bind) && !(anyHas "XF86AudioPause" bind)) "Play/Pause missing from bindl/bindsl or also in plain bind";
  check-no-duplicate-combos =
    chk (dupCombos (bind ++ bindl ++ bindsl) == [ ]) "duplicate key combos: ${toString (dupCombos (bind ++ bindl ++ bindsl))}";
  check-duplicate-combos-control =
    chk (dupCombos [ "A,b,x" "A,b,y" "C,d,z" ] == [ "A,b" ] && dupCombos [ "A,b,x" "A,c,x" ] == [ ]) "duplicate predicate does not discriminate";
  check-proportion-preset-has-arg = chk (!(lib.any emptyPreset bind)) "switch_proportion_preset without argument";
  check-proportion-preset-control = chk (emptyPreset "SUPER,x,switch_proportion_preset," && !(emptyPreset "SUPER,x,switch_proportion_preset,0.5")) "empty-preset predicate does not discriminate";
  check-no-zero-opacity-rules = chk (!(lib.any zeroOpacity windowRule)) "window rule with opacity:0 (ignored by mango)";
  check-zero-opacity-control = chk (zeroOpacity "opacity:0,app_id:^a$" && zeroOpacity "focused_opacity:0" && !(zeroOpacity "focused_opacity:0.01,app_id:^a$")) "opacity predicate does not discriminate";

  check-bind-lists-nonempty =
    chk (lib.all (k: keyLists.${k} != [ ]) [ "bind" "bindl" "bindsl" "mousebind" "axisbind" "gesturebind" "tag_rule" "layer_rule" ]) "an expected bind/rule list is empty: ${toString (lib.filter (k: keyLists.${k} == [ ]) (builtins.attrNames keyLists))}";
  check-bind-rule-min-fields =
    chk (shortKeys == [ ]) "malformed entries (binds need >=3 comma fields, rules >=2 key:value fields): ${lib.concatStringsSep " | " shortKeys}";
  check-min-fields-control =
    chk (badField "bind" "SUPER,P" && !(badField "bind" "NONE,a,b") && badField "tag_rule" "id:1" && badField "layer_rule" "layer_name:x,oops" && !(badField "layer_rule" "layer_name:x,animation_type_open:zoom")) "field-count predicate does not discriminate";

  check-tag-rule-matches-option =
    chk (layoutsOpt != { } && perMonitorOk tagRule layoutsOpt) "tag_rule lacks id:1-9 monitor_name/layout_name entries for monitorLayouts (${builtins.toJSON layoutsOpt})";
  check-tag-rule-one-layout-per-tag-monitor =
    chk (lib.all (name: lib.all (id: lib.length (layoutOf name id) == 1) tagIds) (builtins.attrNames layoutsOpt)) "a (tag, monitor) pair has zero or several tag_rule entries";
  check-tag-rule-fallback-per-tag =
    chk (lib.all (id: lib.elem "id:${toString id},layout_name:${mangoOpts.defaultLayout}" tagRule) tagIds) "fallback tag_rule (defaultLayout ${mangoOpts.defaultLayout}) missing for a tag";
  check-tag-rule-syntax = chk (lib.all tagRuleSyntaxOk tagRule) "malformed tag_rule: ${toString (lib.filter (r: !tagRuleSyntaxOk r) tagRule)}";
  check-tag-rule-control =
    chk (!(perMonitorOk (lib.filter (r: !(has "monitor_name:^${lib.head (builtins.attrNames layoutsOpt)}$" r)) tagRule) layoutsOpt) && !(perMonitorOk tagRule (lib.mapAttrs (_: l: "${l}_x") layoutsOpt))) "per-monitor tag_rule predicate accepts a mutated rule list";

  check-gdk-scale-two-sources =
    chk (sessionVars.GDK_SCALE != "1" && s.env == [ "GDK_SCALE,1" ] && firstScale != null && lib.head firstScale != "1") "GDK_SCALE contract broken: sessionVariables=${toString (sessionVars.GDK_SCALE or "unset")} env=${toString (s.env or [ ])} firstMonitor=${firstMonitor}";
  check-gdk-scale-systemd-forwarded = chk (lib.elem "GDK_SCALE" sysdVars) "GDK_SCALE not in systemd.variables";
  check-systemd-vars-defined = chk (sysdUndefined == [ ]) "systemd.variables without a definition: ${toString sysdUndefined}";
  check-systemd-vars-control = chk (lib.elem "NOPE" (lib.filter (v: !(sessionVars ? ${v}) && !(lib.elem v sysdAllow)) [ "NOPE" "GDK_SCALE" ])) "undefined-variable predicate does not discriminate";

  check-hypridle-no-direct-wlopm =
    chk (hypridleStrings != [ ] && lib.any (runsDpms "on") hypridleStrings && noDirectWlopm hypridleStrings) "hypridle calls wlopm directly (or no mango-dpms command present)";
  check-hypridle-wlopm-control = chk (!(noDirectWlopm [ "x" "wlopm --on '*'" ]) && noDirectWlopm [ "mango-dpms on" ] && runsDpms "on" "a\n/bin/mango-dpms on" && !(runsDpms "on" "/bin/mango-dpms once")) "wlopm/dpms predicates do not discriminate";
  check-hypridle-after-sleep-mango-dpms = chk (runsDpms "on" idle.general.after_sleep_cmd) "after_sleep_cmd lacks mango-dpms on";
  check-hypridle-screen-off-mango-dpms =
    chk (screenOff != null && runsDpms "off" screenOff.on-timeout && runsDpms "on" screenOff.on-resume) "screen-off listener lacks mango-dpms off/on";
  check-hypridle-other-wms-unchanged =
    chk (has "hl.dsp.dpms" idle.general.after_sleep_cmd && has "niri msg action power-on-monitors" idle.general.after_sleep_cmd) "Hyprland/niri dpms branches changed";

  mango-dpms-cmd = idle.general.after_sleep_cmd;
  mango-dpms-drv = lib.head (lib.filter (d: lib.hasSuffix "mango-dpms.drv" d) (builtins.attrNames (builtins.getContext idle.general.after_sleep_cmd)));
  mango-config = hm.xdg.configFile."mango/config.conf".source.outPath;
  mango-config-drv = hm.xdg.configFile."mango/config.conf".source.drvPath;
  mango-package = hm.wayland.windowManager.mango.package.outPath;
  mango-package-drv = hm.wayland.windowManager.mango.package.drvPath;
}
