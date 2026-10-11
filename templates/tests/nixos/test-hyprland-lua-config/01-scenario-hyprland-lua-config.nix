let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hostNames = [ "nixos-desktop" "nixos-laptop" ];
  hmOf = c: c.home-manager.users.krit;
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
  unreadable = p: builtins.unsafeDiscardStringContext p;

  legacyDispatch = text:
    let
      parts = lib.filter builtins.isString (builtins.split "hyprctl[[:space:]]+dispatch[[:space:]]+" text);
    in
    lib.filter (s: !(lib.hasPrefix "'hl." s)) (lib.tail parts);
  snippet = s: builtins.substring 0 50 s;

  execStrings = svc:
    lib.concatMap (k: let v = svc.Service.${k} or [ ]; in lib.toList v) [ "ExecStart" "ExecStop" "ExecStartPre" "ExecStartPost" "ExecReload" ];

  perVariant = _name: c:
    let
      hm = hmOf c;
      lua = hm.xdg.configFile."hypr/hyprland.lua".text;
      idleConf = hm.xdg.configFile."hypr/hypridle.conf".text;
      idle = hm.services.hypridle.settings;
      pkgByName = n: lib.findFirst (p: (p.name or "") == n) null hm.home.packages;
      lockPkg = pkgByName "universal-lock";
      lockText = if lockPkg == null then "" else builtins.readFile "${lockPkg}/bin/universal-lock";
      services = hm.systemd.user.services;
      jetkvm = services.hyprland-jetkvm-teardown or null;
      jetkvmText = if jetkvm == null then "" else lib.concatMapStrings (e: let s = toString e; in if lib.hasPrefix "/nix/store/" s && !(has "/bin/true" s) then builtins.readFile (unreadable s) else "") (execStrings jetkvm);
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
      waybarDrv = if waybarDrvPath == "" then "" else builtins.readFile waybarDrvPath;
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
      "universal-lock-present" = chk (lockPkg != null && lockText != "") "universal-lock package not found in home.packages";
      "hypridle-three-listeners" = chk (builtins.length listeners == 3) "expected 3 listeners, got ${toString (builtins.length listeners)}";
      "hypridle-timeouts-increase" = chk (increasing timeouts) "timeouts not strictly increasing: ${toString timeouts}";
      "hypridle-dpms-lua" = chk (offListener != null && has ''hl.dsp.dpms({ action = "off" })'' offListener.on-timeout && has ''hl.dsp.dpms({ action = "on" })'' (offListener.on-resume or "") && has ''hl.dsp.dpms({ action = "on" })'' idle.general.after_sleep_cmd) "hypridle dpms off/on lua dispatch missing";
      "hypridle-lock-cmd" = chk (lockPkg != null && idle.general.lock_cmd == "${lockPkg}/bin/universal-lock") "lock_cmd is ${idle.general.lock_cmd}";
      "systemd-no-stop-command" = chk (hm.wayland.windowManager.hyprland.systemd.extraCommands == [ "systemctl --user start hyprland-session.target" ]) "extraCommands: ${builtins.toJSON hm.wayland.windowManager.hyprland.systemd.extraCommands}";
      "waybar-service-present" = chk (waybarSvc != null) "systemd.user.services.waybar-hyprland missing";
      "waybar-lua-dispatch-patch" = chk (has "waybar-hyprland-lua-dispatch.patch" waybarDrv) "waybar in waybar-hyprland ExecStart lacks waybar-hyprland-lua-dispatch.patch";
      "waybar-control-stock-unpatched" = chk (!(has "waybar-hyprland-lua-dispatch.patch" (builtins.readFile (unreadable flake.inputs.nixpkgs.legacyPackages.x86_64-linux.waybar.drvPath)))) "stock waybar already carries the patch (check cannot bite)";
      "xwayland-phantom-rule-settings" = chk xwaylandRule "no window_rule with class ^$ + xwayland + no_focus";
      "xwayland-phantom-rule-rendered" = chk (has ''["class"] = "^$"'' lua && has ''["xwayland"] = true'' lua) "rendered lua lacks the XWayland phantom rule";
      "wrapper-capabilities-empty" = chk (c.security.wrappers.Hyprland.capabilities == "") "capabilities: ${c.security.wrappers.Hyprland.capabilities}";
      "with-uwsm" = chk (c.programs.hyprland.withUWSM) "programs.hyprland.withUWSM is false";
    };

  results = lib.mapAttrs perVariant variants;

  controlBad = "hyprctl dispatch workspace 1\nhyprctl dispatch 'hl.dsp.exit()'\nhyprctl   dispatch dpms off";
  controlGood = "hyprctl dispatch 'hl.dsp.exit()' && hyprctl reload";
in
{
  variants = builtins.attrNames variants;
  results = results;
  lua-texts = lib.mapAttrs (_: c: (hmOf c).xdg.configFile."hypr/hyprland.lua".text) variants;
  lock-texts = lib.mapAttrs
    (_: c:
      let p = lib.findFirst (p: (p.name or "") == "universal-lock") null (hmOf c).home.packages;
      in if p == null then "" else builtins.readFile "${p}/bin/universal-lock")
    variants;
  control = {
    "legacy-matcher-flags-bad-text" = chk (builtins.length (legacyDispatch controlBad) == 2) "matcher found ${toString (builtins.length (legacyDispatch controlBad))} legacy uses in control text, expected 2";
    "legacy-matcher-accepts-good-text" = chk (legacyDispatch controlGood == [ ]) "matcher flagged the lua-form control text";
    "variants-cover-both-hosts" = chk (lib.all (h: variants ? ${h}) hostNames) "base hosts missing from variants";
  };
}
