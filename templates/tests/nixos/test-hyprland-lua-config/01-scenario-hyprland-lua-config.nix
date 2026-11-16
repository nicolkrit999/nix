let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostNames = [ "nixos-desktop" "nixos-laptop" ];
  hmOf = c: c.home-manager.users.${c.myconfig.constants.user};
  hyprOn = c: (hmOf c).wayland.windowManager.hyprland.enable;

  variants = lib.listToAttrs (lib.concatMap
    (h:
      let c = flake.nixosConfigurations.${h}.config; in
      [{ name = h; value = c; }]
      ++ lib.concatMap
        (n:
          let sc = c.specialisation.${n}.configuration; in
          lib.optional (hyprOn sc) { name = "${h}+${n}"; value = sc; })
        (builtins.attrNames c.specialisation))
    hostNames);

  has = lib.hasInfix;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  drvVersion = p: (builtins.parseDrvName (lib.removeSuffix ".drv" (builtins.substring 33 (-1) (baseNameOf p)))).version;
  readDrv = d: builtins.readFile (builtins.appendContext d { ${d} = { path = true; }; });
  drvTextOf = s: readDrv (lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext s))));
  lockPkgOf = c: lib.findFirst (p: (p.name or "") == "universal-lock") null (hmOf c).home.packages;
  lockTextOf = p: if p == null then "" else builtins.unsafeDiscardStringContext (p.text or "");

  legacyDispatch = text:
    let
      parts = lib.filter builtins.isString (builtins.split "hyprctl[[:space:]]+dispatch[[:space:]]+" text);
    in
    lib.filter (s: !(lib.hasPrefix "'hl." s)) (lib.tail parts);
  snippet = s: builtins.substring 0 50 s;

  ecosystemBlock = text:
    let parts = lib.splitString ''["ecosystem"] = {'' text;
    in if lib.length parts != 2 then "" else lib.head (lib.splitString "}" (lib.elemAt parts 1));
  newsDisabled = text: has ''["no_update_news"] = true'' (ecosystemBlock text);

  execStrings = svc:
    lib.concatMap (k: let v = svc.Service.${k} or [ ]; in lib.toList v) [ "ExecStart" "ExecStop" "ExecStartPre" "ExecStartPost" "ExecReload" ];

  scratchBindClasses = text:
    lib.concatMap
      (l:
        let m = builtins.match ".*[[]workspace special:magic[]][^\"]*(--class|--name) ([^ \"]+).*" l;
        in lib.optional (m != null) (builtins.elemAt m 1))
      (lib.splitString "\n" text);
  scratchRuleClasses = text:
    lib.concatMap
      (b:
        let
          ms = map (l: builtins.match ''.*[[]"class"[]] = "\^\(([^)]*)\)\$".*'' l) (lib.splitString "\n" b);
          found = lib.filter (m: m != null) ms;
        in
        lib.optional (has ''["workspace"] = "special:magic"'' b && found != [ ]) (builtins.head (builtins.head found)))
      (lib.splitString "hl.window_rule({" text);
  scratchUnmatched = text:
    let rules = scratchRuleClasses text; in
    lib.filter (cls: !(lib.any (r: builtins.match r cls != null) rules)) (scratchBindClasses text);

  autoHdrRuleIn = text:
    lib.any (b: has ''["class"] = ".*"'' b && has ''["no_auto_hdr"] = true'' b) (lib.splitString "hl.window_rule({" text);

  hdrToggleOf = c: lib.findFirst (p: (p.name or "") == "hypr-hdr-toggle") null (hmOf c).home.packages;
  hdrToggleText = p: if p == null then "" else builtins.unsafeDiscardStringContext (p.text or "");
  hdrMonitorKeys = text:
    let
      m = builtins.match ".*hl[.]monitor[(][{]([^}]*)[}][)].*" (builtins.replaceStrings [ "\n" ] [ " " ] text);
      body = if m == null then "" else lib.head m;
      fields = lib.filter (f: f != "") (map lib.trim (lib.splitString "," body));
    in
    map (f: lib.trim (lib.head (lib.splitString "=" f))) fields;
  hdrHardcodedMonitor = text: lib.any (l: builtins.match ".*(eDP|DP|HDMI|DVI|VGA)-[0-9].*" l != null) (lib.splitString "\n" text);

  perVariant = _name: c:
    let
      hm = hmOf c;
      lua = hm.xdg.configFile."hypr/hyprland.lua".text;
      idleConf = hm.xdg.configFile."hypr/hypridle.conf".text;
      idle = hm.services.hypridle.settings;
      lockPkg = lockPkgOf c;
      lockText = lockTextOf lockPkg;
      services = hm.systemd.user.services;
      jetkvm = services.hyprland-jetkvm-teardown or null;
      jetkvmText = if jetkvm == null then "" else lib.concatMapStrings (e: let s = toString e; in if lib.hasPrefix "/nix/store/" s && !(has "/bin/true" s) then drvTextOf s else "") (execStrings jetkvm);
      svcText = lib.concatMapStrings (s: lib.concatStringsSep "\n" (map toString (execStrings s)) + "\n") (lib.attrValues services);
      waybarConf = hm.xdg.configFile."waybar-hyprland/config".text or "";
      corpus = {
        "hyprland.lua" = lua;
        "hypridle.conf" = idleConf;
        "waybar-hyprland/config" = waybarConf;
        "universal-lock" = lockText;
        "user services" = svcText;
        "jetkvm teardown" = jetkvmText;
      };
      listeners = idle.listener;
      timeouts = map (l: l.timeout) listeners;
      increasing = l: lib.all (i: builtins.elemAt l i < builtins.elemAt l (i + 1)) (lib.range 0 (builtins.length l - 2));
      offListener = lib.findFirst (l: has "dpms" (l.on-timeout or "")) null listeners;
      waybarSvc = services.waybar-hyprland or null;
      waybarExec = if waybarSvc == null then "" else toString (lib.head (lib.toList waybarSvc.Service.ExecStart));
      waybarDrvPath = lib.findFirst (lib.hasSuffix ".drv") "" (builtins.attrNames (builtins.getContext waybarExec));
      hdrPkg = hdrToggleOf c;
      hdrText = hdrToggleText hdrPkg;
      noAutoHdrSettings = lib.any
        (r: (r.match.class or "") == ".*" && (r.no_auto_hdr or false) == true)
        hm.wayland.windowManager.hyprland.settings.window_rule;
      xwaylandRule = lib.any
        (r: (r.match.class or "") == "^$" && (r.match.xwayland or false) == true && (r.no_focus or false) == true)
        hm.wayland.windowManager.hyprland.settings.window_rule;
    in
    {
      "lua-text-nonempty" = chk (builtins.stringLength lua > 1000) "rendered hyprland.lua suspiciously short";
      "config-type-lua" = chk (hm.wayland.windowManager.hyprland.configType == "lua") "configType is ${hm.wayland.windowManager.hyprland.configType}";
      "no-json-unicode-escape" = chk (!(has "\\u00" lua)) "hyprland.lua contains a JSON \\u00XX escape (invalid Lua)";
      "no-legacy-dispatch" =
        let bad = lib.concatLists (lib.mapAttrsToList (k: t: map (s: "${k}: hyprctl dispatch ${snippet s}") (legacyDispatch t)) corpus);
        in chk (bad == [ ]) (lib.concatStringsSep " | " bad);
      "universal-lock-present" = chk (lockPkg != null && lockText != "") (if lockPkg == null then "universal-lock package not found in home.packages" else "universal-lock derivation has no text attribute");
      "hypridle-three-listeners" = chk (builtins.length listeners == 3) "expected 3 listeners, got ${toString (builtins.length listeners)}";
      "hypridle-timeouts-increase" = chk (increasing timeouts) "timeouts not strictly increasing: ${toString timeouts}";
      "hypridle-dpms-lua" = chk (offListener != null && has ''hl.dsp.dpms({ action = "off" })'' offListener.on-timeout && has ''hl.dsp.dpms({ action = "on" })'' (offListener.on-resume or "") && has ''hl.dsp.dpms({ action = "on" })'' idle.general.after_sleep_cmd) "hypridle dpms off/on lua dispatch missing";
      "hypridle-lock-cmd" = chk (lockPkg != null && idle.general.lock_cmd == "${lockPkg}/bin/universal-lock") "lock_cmd is ${idle.general.lock_cmd}";
      "systemd-no-stop-command" = chk (hm.wayland.windowManager.hyprland.systemd.extraCommands == [ "systemctl --user start hyprland-session.target" ]) "extraCommands: ${builtins.toJSON hm.wayland.windowManager.hyprland.systemd.extraCommands}";
      "waybar-service-present" = chk (waybarSvc != null) "systemd.user.services.waybar-hyprland missing";
      "waybar-lua-dispatch-upstream" = chk (waybarDrvPath != "" && lib.versionAtLeast (drvVersion waybarDrvPath) "0.16.0") "waybar in waybar-hyprland ExecStart is ${drvVersion waybarDrvPath}, older than 0.16.0 (first release with Lua IPC dispatch)";
      "waybar-version-parser-control" = chk (drvVersion "/nix/store/00000000000000000000000000000000-waybar-0.15.0.drv" == "0.15.0" && !(lib.versionAtLeast "0.15.0" "0.16.0")) "waybar version parser or comparison is broken (check cannot bite)";
      "xwayland-phantom-rule-settings" = chk xwaylandRule "no window_rule with class ^$ + xwayland + no_focus";
      "xwayland-phantom-rule-rendered" = chk (has ''["class"] = "^$"'' lua && has ''["xwayland"] = true'' lua) "rendered lua lacks the XWayland phantom rule";
      "update-news-disabled" = chk (newsDisabled lua && hm.wayland.windowManager.hyprland.settings.config.ecosystem.no_update_news == true) "ecosystem.no_update_news is not true in the settings or in the rendered hyprland.lua (block: ${ecosystemBlock lua})";
      "no-hyprland-wrapper" = chk (c.programs.hyprland.enable && !(c.security.wrappers ? Hyprland)) "security.wrappers.Hyprland exists or programs.hyprland is off";
      "jetkvm-teardown-gated-no-ls-pipe" = chk (jetkvm == null || ((jetkvm.Service.ExecCondition or "") != "" && !(has "| head" jetkvmText))) "hyprland-jetkvm-teardown lacks ExecCondition or still pipes ls into head";
      "scratch-binds-have-window-rules" =
        let
          bad = scratchUnmatched lua;
        in
        chk (bad == [ ]) "scratch bind class without special:magic window rule: ${toString bad}";
      "no-auto-hdr-rule-settings" = chk noAutoHdrSettings "no window_rule with class .* and no_auto_hdr = true in settings";
      "no-auto-hdr-rule-rendered" = chk (autoHdrRuleIn lua) "rendered lua has no hl.window_rule block with class .* and no_auto_hdr = true";
      "hdr-toggle-package-present" = chk (hdrPkg != null && hdrText != "") (if hdrPkg == null then "hypr-hdr-toggle not in home.packages" else "hypr-hdr-toggle derivation has no text attribute");
      "hdr-toggle-flips-cm-preset" = chk (has ''"hdr"'' hdrText && has ''new=srgb'' hdrText && has "hyprctl eval" hdrText && has "colorManagementPreset" hdrText) "hypr-hdr-toggle script does not toggle between srgb and hdr via hyprctl eval";
      "hdr-toggle-sends-only-output-and-cm" = chk (hdrMonitorKeys hdrText == [ "output" "cm" ]) "hl.monitor keys sent by hypr-hdr-toggle: ${toString (hdrMonitorKeys hdrText)}";
      "hdr-toggle-no-hardcoded-monitor" = chk (hdrText != "" && !(hdrHardcodedMonitor hdrText)) "hypr-hdr-toggle script names a connector (eDP-1, DP-2, ...) or is empty";
      "with-uwsm" = chk c.programs.hyprland.withUWSM "programs.hyprland.withUWSM is false";
    };

  results = lib.mapAttrs perVariant variants;

  ctlBinds = ''
    hl.bind("a", (hl.dsp.exec_cmd("[workspace special:magic] kitty --class scratch-term")))
    hl.bind("b", (hl.dsp.exec_cmd("[workspace special:magic] zen --no-remote --name scratch-browser")))
  '';
  ctlRule = cls: ''
    hl.window_rule({
      ["match"] = {
        ["class"] = "^(${cls})$"
      },
      ["workspace"] = "special:magic"
    })
  '';
  ctlEcoTrue = ''
    hl.config({
      ["ecosystem"] = {
        ["no_update_news"] = true
      }
    })
  '';
  ctlEcoFalse = ''
    hl.config({
      ["ecosystem"] = {
        ["no_update_news"] = false
      }
    })
  '';
  ctlEcoElsewhere = ''
    hl.config({
      ["ecosystem"] = {
        ["no_donation_nag"] = true
      },
      ["misc"] = {
        ["no_update_news"] = true
      }
    })
  '';
  ctlHdrGood = ''hyprctl eval "hl.monitor({ output = \"$out\", cm = \"$new\" })"'';
  ctlHdrExtra = ''hyprctl eval "hl.monitor({ output = \"$out\", cm = \"$new\", mode = \"preferred\" })"'';
  ctlHdrRule = r: ''
    hl.window_rule({
      ["match"] = {
        ["class"] = "${r}"
      },
      ["no_auto_hdr"] = true
    })
  '';
  controlBad = "hyprctl dispatch workspace 1\nhyprctl dispatch 'hl.dsp.exit()'\nhyprctl   dispatch dpms off";
  controlGood = "hyprctl dispatch 'hl.dsp.exit()' && hyprctl reload";
in
{
  variants = builtins.attrNames variants;
  inherit results;
  lua-texts = lib.mapAttrs (_: c: (hmOf c).xdg.configFile."hypr/hyprland.lua".text) variants;
  lock-texts = lib.mapAttrs (_: c: lockTextOf (lockPkgOf c)) variants;
  control = {
    "legacy-matcher-flags-bad-text" = chk (builtins.length (legacyDispatch controlBad) == 2) "matcher found ${toString (builtins.length (legacyDispatch controlBad))} legacy uses in control text, expected 2";
    "legacy-matcher-accepts-good-text" = chk (legacyDispatch controlGood == [ ]) "matcher flagged the lua-form control text";
    "pipe-matcher-flags-ls-head" = chk (has "| head" "ls -1 dir | head -n1" && !(has "| head" "for d in dir/*/; do break; done")) "ls-into-head matcher does not discriminate";
    "scratch-matcher-extracts-class-and-name" = chk (scratchBindClasses ctlBinds == [ "scratch-term" "scratch-browser" ]) "extracted ${toString (scratchBindClasses ctlBinds)}";
    "scratch-matcher-flags-missing-rule" = chk (scratchUnmatched (ctlBinds + ctlRule "scratch-term") == [ "scratch-browser" ]) "got ${toString (scratchUnmatched (ctlBinds + ctlRule "scratch-term"))}";
    "scratch-matcher-accepts-full-rules" = chk (scratchUnmatched (ctlBinds + ctlRule "scratch-term" + ctlRule "scratch-browser") == [ ]) "flagged despite rules";
    "scratch-matcher-flags-wrong-class" = chk (scratchUnmatched (ctlBinds + ctlRule "scratch-term" + ctlRule "scratch-browse") == [ "scratch-browser" ]) "near-miss class accepted";
    "update-news-matcher-flags-false-and-foreign-block" = chk (!(newsDisabled ctlEcoFalse) && !(newsDisabled ctlEcoElsewhere) && newsDisabled ctlEcoTrue) "matcher accepts false / a no_update_news outside the ecosystem block, or rejects the true form";
    "hdr-keys-matcher-accepts-output-and-cm" = chk (hdrMonitorKeys ctlHdrGood == [ "output" "cm" ]) "got ${toString (hdrMonitorKeys ctlHdrGood)}";
    "hdr-keys-matcher-flags-extra-key" = chk (hdrMonitorKeys ctlHdrExtra == [ "output" "cm" "mode" ]) "extra key not seen: ${toString (hdrMonitorKeys ctlHdrExtra)}";
    "hdr-connector-matcher-discriminates" = chk (hdrHardcodedMonitor "x\nhl.monitor({ output = \"eDP-1\" })" && !(hdrHardcodedMonitor ctlHdrGood)) "connector matcher does not discriminate";
    "hdr-rule-matcher-discriminates" = chk (autoHdrRuleIn (ctlHdrRule ".*") && !(autoHdrRuleIn (ctlHdrRule "^(mpv)$")) && !(autoHdrRuleIn ''hl.window_rule({ ["match"] = { ["class"] = ".*" }, ["float"] = true })'')) "no_auto_hdr rule matcher accepts a non-catch-all or a rule without no_auto_hdr";
    "variants-cover-both-hosts" = chk (lib.all (h: variants ? ${h}) hostNames) "base hosts missing from variants";
  };
}
