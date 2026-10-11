let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  desktop = flake.nixosConfigurations.nixos-desktop.config;
  laptop = flake.nixosConfigurations.nixos-laptop.config;
  homeSpec = laptop.specialisation.home.configuration;

  toNum = x: if builtins.isString x then (builtins.fromJSON x) + 0.0 else x + 0.0;
  round = x: builtins.floor (toNum x + 0.5);
  orNull = a: n: a.${n} or null;
  numEq = a: b: a != null && b != null && toNum a == toNum b;
  chk = errs: if errs == [ ] then "ok" else "FAIL: ${lib.concatStringsSep "; " errs}";

  fromHypr = list:
    builtins.listToAttrs (map
      (m:
        let
          mm = builtins.match "([0-9]+)x([0-9]+)@([0-9.]+)" (m.mode or "");
          pos = builtins.match "(-?[0-9]+)x(-?[0-9]+)" (m.position or "");
        in
        {
          name = lib.removePrefix "desc:" m.output;
          value = {
            w = if mm == null then null else toNum (builtins.elemAt mm 0);
            h = if mm == null then null else toNum (builtins.elemAt mm 1);
            r = if mm == null then null else round (builtins.elemAt mm 2);
            scale = if builtins.isString (m.scale or null) then null else orNull m "scale";
            x = if pos == null then null else toNum (builtins.elemAt pos 0);
            y = if pos == null then null else toNum (builtins.elemAt pos 1);
            rot = (m.transform or 0) * 90;
            off = (m.mirror or null) != null || (m.disabled or false);
          };
        })
      (lib.filter (m: (m.output or "") != "") list));

  fromMango = list:
    builtins.listToAttrs (map
      (str:
        let
          kv = builtins.listToAttrs (map
            (f:
              let p = lib.splitString ":" f; in
              { name = builtins.head p; value = lib.concatStringsSep ":" (builtins.tail p); })
            (lib.splitString "," str));
          num = k: if kv ? ${k} then toNum kv.${k} else null;
        in
        {
          name = lib.removeSuffix "$" (lib.removePrefix "^" kv.name);
          value = {
            w = num "width";
            h = num "height";
            r = if kv ? refresh then round kv.refresh else null;
            scale = num "scale";
            x = num "x";
            y = num "y";
            rot = if kv ? rr then (builtins.fromJSON kv.rr) * 90 else 0;
            off = (kv.disable or "0") == "1";
          };
        })
      list);

  fromNiri = outs:
    lib.mapAttrs
      (_: o: {
        w = if o ? mode then toNum o.mode.width else null;
        h = if o ? mode then toNum o.mode.height else null;
        r = if o ? mode then round o.mode.refresh else null;
        scale = o.scale or null;
        x = if o ? position then toNum o.position.x else null;
        y = if o ? position then toNum o.position.y else null;
        rot = o.transform.rotation or 0;
        off = !(o.enable or true);
      })
      outs;

  hasOut = srcs: n: lib.all (s: s.data ? ${n}) srcs;

  compareField = names: srcs: label: get: eq:
    lib.concatMap
      (n:
        let
          vals = map (s: { inherit (s) tag; v = get s.data.${n}; }) srcs;
          first = builtins.head vals;
        in
        lib.optional (!(lib.all (x: eq first.v x.v) vals))
          "${n} ${label}: ${lib.concatStringsSep " vs " (map (x: "${x.tag}=${toString x.v}") vals)}")
      (lib.filter (hasOut srcs) names);

  bothSet = a: b: a != null && b != null && a == b;

  presence = names: srcs:
    lib.concatMap
      (n:
        lib.concatMap
          (s: lib.optional (!(s.data ? ${n})) "${n} missing in ${s.tag}")
          srcs)
      names;

  activeNames = names: srcs: lib.filter (n: hasOut srcs n && lib.all (s: !s.data.${n}.off) srcs) names;

  allChecks = names: srcs: {
    presence = presence names srcs;
    width = compareField (activeNames names srcs) srcs "width" (o: o.w) bothSet;
    height = compareField (activeNames names srcs) srcs "height" (o: o.h) bothSet;
    refresh = compareField (activeNames names srcs) srcs "refresh" (o: o.r) bothSet;
    scale = compareField (activeNames names srcs) srcs "scale" (o: o.scale) numEq;
    rotation = compareField names srcs "rotation" (o: o.rot) (a: b: a == b);
    position =
      compareField (if lib.length (activeNames names srcs) < 2 then [ ] else activeNames names srcs) srcs "position"
        (o: "${toString o.x},${toString o.y}")
        (a: b: a == b && a != ",");
  };

  dHypr = { tag = "hyprland"; data = fromHypr desktop.myconfig.programs.hyprland.monitors; };
  dMango = { tag = "mango"; data = fromMango desktop.myconfig.programs.mango.monitors; };
  dNiri = { tag = "niri"; data = fromNiri desktop.myconfig.programs.niri.outputs; };
  dSrcs = [ dHypr dMango dNiri ];
  dNames = [ "DP-1" "DP-2" "HDMI-A-1" ];
  dRes = allChecks dNames dSrcs;

  lHypr = { tag = "hyprland"; data = fromHypr laptop.myconfig.programs.hyprland.monitors; };
  lMango = { tag = "mango"; data = fromMango laptop.myconfig.programs.mango.monitors; };
  lNiri = { tag = "niri"; data = fromNiri laptop.myconfig.programs.niri.outputs; };
  lSrcs = [ lHypr lMango lNiri ];
  lRes = allChecks [ "eDP-1" ] lSrcs;

  sHyprRaw = homeSpec.myconfig.programs.hyprland.monitors;
  sHypr = { tag = "hyprland"; data = fromHypr sHyprRaw; };
  sNiri = { tag = "niri"; data = fromNiri homeSpec.myconfig.programs.niri.outputs; };
  sNames = builtins.attrNames sHypr.data;
  sRes = allChecks sNames [ sHypr sNiri ];
  sDeclared = sNames;
  sDescNames = map (m: lib.removePrefix "desc:" m.output) (lib.filter (m: lib.hasPrefix "desc:" (m.output or "")) sHyprRaw);

  mutate = f: srcs: map (s: if s.tag == "niri" then s // { data = lib.mapAttrs (_: f) s.data; } else s) srcs;
  controlOf = f: allChecks dNames (mutate f dSrcs);
  nonEmpty = l: l != [ ];

  login = homeSpec.services.logind.settings.Login;
in
{
  check-desktop-presence = chk dRes.presence;
  check-desktop-width = chk dRes.width;
  check-desktop-height = chk dRes.height;
  check-desktop-refresh = chk dRes.refresh;
  check-desktop-scale = chk dRes.scale;
  check-desktop-rotation = chk dRes.rotation;
  check-desktop-position = chk dRes.position;
  check-desktop-hdmi-off =
    chk (map (s: "HDMI-A-1 is not disabled/mirrored in ${s.tag}") (lib.filter (s: !(s.data.HDMI-A-1.off or false)) dSrcs));
  check-laptop-presence = chk lRes.presence;
  check-laptop-mode = chk (lRes.width ++ lRes.height ++ lRes.refresh);
  check-laptop-scale = chk lRes.scale;
  check-laptop-position = chk lRes.position;
  check-laptop-no-rotation = chk lRes.rotation;

  check-home-spec-covered =
    chk (lib.optional (sDescNames == [ ]) "no desc: monitors in the home specialisation" ++ lib.optional (!(lib.all (n: sNiri.data ? ${n}) sDescNames)) "a desc: monitor has no niri output with the same make/model/serial");
  check-home-spec-mode = chk (sRes.width ++ sRes.height ++ sRes.refresh);
  check-home-spec-scale = chk sRes.scale;
  check-home-spec-rotation = chk sRes.rotation;
  check-home-spec-position = chk sRes.position;
  check-home-spec-niri-no-extras =
    chk (map (n: "niri output ${n} has no hyprland monitor") (lib.filter (n: !(sHypr.data ? ${n})) (builtins.attrNames sNiri.data)));
  check-home-spec-workspace-monitors =
    let
      ms = map (w: lib.removePrefix "desc:" w.monitor) homeSpec.myconfig.programs.hyprland.monitorWorkspaces;
    in
    chk (lib.optional (ms == [ ]) "no monitorWorkspaces" ++ map (m: "monitorWorkspaces monitor ${m} is not a declared output") (lib.filter (m: !(lib.elem m sDeclared)) ms));
  check-home-spec-wallpaper-targets =
    let
      ts = map (w: lib.removePrefix "desc:" w.targetMonitor) homeSpec.myconfig.constants.wallpapers;
    in
    chk (lib.optional (ts == [ ]) "no wallpapers" ++ map (m: "wallpaper targetMonitor ${m} is not a declared output") (lib.filter (m: !(lib.elem m sDeclared)) ts));
  check-home-spec-lid-ignore =
    chk (map (k: "${k} is not ignore") (lib.filter (k: (login.${k} or null) != "ignore") [ "HandleLidSwitch" "HandleLidSwitchExternalPower" "HandleLidSwitchDocked" ]));
  check-control-scale-bites =
    chk (lib.optional (!(nonEmpty (controlOf (o: o // { scale = 2.0; })).scale)) "scale comparison did not flag a mutated niri scale");
  check-control-refresh-bites =
    chk (lib.optional (!(nonEmpty (controlOf (o: o // { r = 61; })).refresh)) "refresh comparison did not flag a mutated niri refresh");
  check-control-position-bites =
    chk (lib.optional (!(nonEmpty (controlOf (o: o // { x = 7.0; off = false; })).position)) "position comparison did not flag a mutated niri position");
  check-control-rotation-bites =
    chk (lib.optional (!(nonEmpty (controlOf (o: o // { rot = 0; })).rotation)) "rotation comparison did not flag a mutated niri rotation");
  check-control-position-skips-disabled =
    chk (lib.optional (lib.any (e: lib.hasPrefix "HDMI-A-1" e) (controlOf (o: o // { x = 99999.0; })).position) "disabled/mirrored HDMI-A-1 is wrongly part of the position comparison");
}
