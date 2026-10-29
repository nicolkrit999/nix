let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  fx = import ../../lib/fixture-host.nix flake;
  mk = lib.mkForce;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  twin = extra: fx.mkNixos [{ myconfig.programs.cosmic.enable = mk true; } extra];
  plain = twin { };
  custom = twin { myconfig.services.hypridle.screenOffTimeout = mk 123; };
  off = fx.mkNixos [{ myconfig.programs.cosmic.enable = mk false; myconfig.services.hypridle.screenOffTimeout = mk 123; }];

  desktop = flake.nixosConfigurations.nixos-desktop;

  cosmicOf = t: (fx.hmOf t).wayland.desktopManager.cosmic;
  opt = v: { __type = "optional"; value = v; };
  timeoutOf = t: t.config.myconfig.services.hypridle.screenOffTimeout;
  u32Max = 4294967295;
  idleKey = "com.system76.CosmicIdle";

  idleProblemsOf = i: secs:
    lib.optional (i.screen_off_time != opt (secs * 1000)) "screen_off_time is ${builtins.toJSON i.screen_off_time}, expected ${toString (secs * 1000)} ms"
    ++ lib.optional (i.suspend_on_ac_time != opt null) "suspend_on_ac_time is ${builtins.toJSON i.suspend_on_ac_time}"
    ++ lib.optional (i.suspend_on_battery_time != opt null) "suspend_on_battery_time is ${builtins.toJSON i.suspend_on_battery_time}"
    ++ lib.optional (builtins.attrNames i != [ "screen_off_time" "suspend_on_ac_time" "suspend_on_battery_time" ]) "unexpected idle keys ${builtins.toJSON (builtins.attrNames i)}";
  idleProblems = t: idleProblemsOf (cosmicOf t).idle (timeoutOf t);

  coffeeLib = builtins.readFile "${flake.outPath}/modules/nixos/services/power/coffee/coffee-lib.sh";
  coffeeKeys =
    let m = builtins.match ".*COSMIC_IDLE_KEYS=\\(([^)]*)\\).*" coffeeLib; in
    if m == null then [ ] else lib.filter (s: s != "") (lib.splitString " " (lib.head m));
in
{
  results = {
    "idle: screen_off_time is hypridle screenOffTimeout in ms, both suspend timers None (default)" =
      failIf (idleProblems plain);
    "idle: a non-default hypridle timeout is converted (123 s gives 123000 ms), suspend timers stay None" =
      failIf (idleProblems custom ++ lib.optional (timeoutOf custom != 123) "twin did not take the timeout");
    "idle: the default and the custom twin differ, so the conversion is really derived" =
      if (cosmicOf plain).idle.screen_off_time != (cosmicOf custom).idle.screen_off_time then ok else "FAIL: timeout change did not reach cosmic idle";
    "idle: the screen-off value fits COSMIC's u32 milliseconds (default twin)" =
      if (timeoutOf plain) * 1000 <= u32Max then ok else "FAIL: ${toString (timeoutOf plain)} s overflows u32 ms";
    "idle: configFile CosmicIdle entries equal the idle settings, version 1" =
      let f = (cosmicOf custom).configFile.${idleKey} or null; in
      if f != null && f.entries == (cosmicOf custom).idle && f.version == 1 then ok else "FAIL: configFile ${idleKey} is ${builtins.toJSON f}";
    "idle: coffee's COSMIC_IDLE_KEYS are exactly the keys emitted here" =
      let k = lib.sort (a: b: a < b) coffeeKeys; in
      if k == builtins.attrNames (cosmicOf plain).idle then ok else "FAIL: coffee keys ${builtins.toJSON k}";
    "idle: coffee reads the same config directory (com.system76.CosmicIdle, version 1)" =
      if lib.hasInfix "${idleKey}/v1" coffeeLib then ok else "FAIL: coffee-lib.sh does not point at ${idleKey}/v1";
    "idle: cosmic off emits no idle settings and no CosmicIdle file even with a hypridle timeout set" =
      let c = cosmicOf off; in
      failIf (
        lib.optional (c.idle != null) "idle set with cosmic off"
        ++ lib.optional (c.configFile ? ${idleKey}) "${idleKey} configFile emitted with cosmic off"
      );
    "real desktop: screen_off_time is its own hypridle screenOffTimeout in ms, suspend timers None" =
      failIf (idleProblems desktop);
    "real hosts: hypridle screenOffTimeout is a positive int whose ms value fits u32 (desktop and laptop)" =
      failIf (lib.concatMap
        (n:
          let v = timeoutOf { config = flake.nixosConfigurations.${n}.config; }; in
          lib.optional (!(builtins.isInt v) || v <= 0 || v * 1000 > u32Max) "${n}: screenOffTimeout ${builtins.toJSON v}")
        [ "nixos-desktop" "nixos-laptop" ]);
    "idle: control, a screen-off value in seconds instead of ms is detected" =
      detects "seconds instead of ms" (idleProblemsOf ((cosmicOf plain).idle // { screen_off_time = opt (timeoutOf plain); }) (timeoutOf plain));
    "idle: control, a set suspend timer is detected" =
      detects "suspend timer Some" (idleProblemsOf ((cosmicOf plain).idle // { suspend_on_ac_time = opt 180000; }) (timeoutOf plain));
    "idle: control, an extra idle key is detected" =
      detects "extra key" (idleProblemsOf ((cosmicOf plain).idle // { extra = 1; }) (timeoutOf plain));
  };
}
