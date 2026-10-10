let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  hm = flake.nixosConfigurations.nixos-desktop.config.home-manager.users.krit;
  s = hm.wayland.windowManager.mango.settings;
  idle = hm.services.hypridle.settings;

  bind = s.bind or [ ];
  bindl = s.bindl or [ ];
  bindsl = s.bindsl or [ ];
  windowRule = s.window_rule or [ ];
  execOnce = s.exec_once or [ ];

  has = infix: str: lib.hasInfix infix str;
  anyHas = infix: list: lib.any (has infix) list;
  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  combo = b: lib.concatStringsSep "," (lib.take 2 (lib.splitString "," b));

  listeners = idle.listener;
  screenOff = lib.findFirst (l: has "wlopm" (l.on-timeout or "") || has "mango-dpms" (l.on-timeout or "")) null listeners;
  hypridleStrings = [ idle.general.after_sleep_cmd ] ++ lib.concatMap (l: [ (l.on-timeout or "") (l.on-resume or "") ]) listeners;
in
{
  check-pip-bind = chk (anyHas "SUPER,P,spawn," (lib.filter (b: has "/bin/mango-pip" b) bind)) "SUPER,P does not spawn mango-pip";
  check-scratchpad-bind = chk (lib.elem "SUPER+ALT,Z,toggle_scratchpad" bind) "SUPER+ALT,Z is not toggle_scratchpad";
  check-scratch-binds =
    let
      scratch = lib.filter (b: has "/bin/mango-scratch " b) bind;
      combos = map combo scratch;
    in
    chk (lib.all (c: lib.elem c combos) [ "SUPER+SHIFT,Return" "SUPER+SHIFT,F" "SUPER+SHIFT,B" ]) "scratch binds not routed through mango-scratch: ${toString combos}";
  check-scratch-rules-special-tag =
    chk (lib.all (a: lib.any (r: has "tags:0," r && has "app_id:^${a}$" r) windowRule) [ "scratch-term" "scratch-fs" ]) "scratch window rules lack tags:0";
  check-hdmi-disabled =
    chk (lib.any (r: has "name:^HDMI-A-1$" r && has ",disable:1" r) s.monitor_rule) "HDMI-A-1 monitor rule lacks disable:1";
  check-no-window-rule-once = chk (!(anyHas "zen" (s.window_rule_once or [ ])) && (s.window_rule_once or [ ]) == [ ]) "window_rule_once is not empty";
  check-mango-place-startup = chk (anyHas "/bin/mango-place DP-1 ^zen-beta$ -- " execOnce) "mango-place startup line missing";
  check-gdk-scale-env = chk (lib.elem "GDK_SCALE,1" (s.env or [ ])) "env lacks GDK_SCALE,1";
  check-no-plain-exec = chk (!(s ? exec) || s.exec == [ ]) "plain exec entries present (use exec_once)";
  check-bindl-media = chk (anyHas "XF86AudioRaiseVolume" bindl && anyHas "XF86AudioNext" bindl) "bindl lacks volume/next binds";
  check-bindsl-play-pause = chk (anyHas "XF86AudioPlay" bindsl && anyHas "XF86AudioPause" bindsl) "bindsl lacks Play/Pause";
  check-media-keys-not-in-bind = chk (!(anyHas "XF86AudioPlay" bind) && !(anyHas "XF86AudioPause" bind)) "Play/Pause also in plain bind";
  check-no-duplicate-combos =
    let all = map combo (bind ++ bindl ++ bindsl); in
    chk (lib.length all == lib.length (lib.unique all)) "duplicate key combos: ${toString (lib.filter (c: lib.length (lib.filter (x: x == c) all) > 1) (lib.unique all))}";
  check-launch6-fullscreen = chk (lib.elem "NONE,XF86Launch6,togglefullscreen," bind) "XF86Launch6 is not togglefullscreen";
  check-proportion-preset-has-arg = chk (!(lib.any (b: lib.hasSuffix "switch_proportion_preset," b) bind)) "switch_proportion_preset without argument";
  check-no-zero-opacity-rules = chk (!(lib.any (r: builtins.match ".*opacity:0(,.*)?" r != null) windowRule)) "window rule with opacity:0 (ignored by mango)";

  check-hypridle-no-wlopm-wildcard =
    chk (!(lib.any (str: has "wlopm" str) hypridleStrings)) "hypridle still calls wlopm directly";
  check-hypridle-after-sleep-mango-dpms = chk (has "/bin/mango-dpms on" idle.general.after_sleep_cmd) "after_sleep_cmd lacks mango-dpms on";
  check-hypridle-screen-off-mango-dpms =
    chk (screenOff != null && has "/bin/mango-dpms off" screenOff.on-timeout && has "/bin/mango-dpms on" screenOff.on-resume) "screen-off listener lacks mango-dpms off/on";
  check-hypridle-other-wms-unchanged =
    chk (has "hl.dsp.dpms" idle.general.after_sleep_cmd && has "niri msg action power-on-monitors" idle.general.after_sleep_cmd) "Hyprland/niri dpms branches changed";

  mango-dpms-cmd = idle.general.after_sleep_cmd;
  mango-dpms-drv = lib.head (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext idle.general.after_sleep_cmd)));
  mango-config = hm.xdg.configFile."mango/config.conf".source.outPath;
  mango-config-drv = hm.xdg.configFile."mango/config.conf".source.drvPath;
  mango-package = hm.wayland.windowManager.mango.package.outPath;
}
