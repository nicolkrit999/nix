{ host }:
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  sys = flake.nixosConfigurations.${host};
  c = sys.config;
  twin = modules: (sys.extendModules { inherit modules; }).config;
  mk = lib.mkForce;
  over = lib.mkOverride 10;

  ok = "ok";
  failIf = problems: if problems == [ ] then ok else "FAIL: ${builtins.concatStringsSep "; " (lib.unique problems)}";
  detects = what: problems:
    if problems != [ ] then ok else "FAIL: control did not detect: ${what}";

  hm = cfg: cfg.home-manager.users.${cfg.myconfig.constants.user};

  guardRe = "(/nix/store/[^ ]+-nix-busy) && exit 0; (.+)";
  guardOf = l: builtins.match guardRe (builtins.unsafeDiscardStringContext (l.on-timeout or ""));

  busyBodyProblems = text:
    (lib.optional (!(lib.hasInfix "pgrep" text)) "busy script has no pgrep")
    ++ (lib.optional (lib.hasInfix "|| true" text) "busy script swallows the pgrep status with || true")
    ++ (lib.optional (builtins.match ".*(^|\n)[ \t]*exit [0-9]+.*" text != null) "busy script has an explicit exit")
    ++ (lib.optional (lib.hasInfix "set -e" text) "busy script uses set -e")
    ++ (lib.optional (!(lib.hasInfix "nixos-rebuild" text && lib.hasInfix "nix.build" text)) "busy script does not match nix build / nixos-rebuild");

  idleProblems = cfg:
    let
      h = hm cfg;
      s = h.services.hypridle.settings;
      ls = s.listener;
      opt = cfg.myconfig.services.hypridle;
      guards = map guardOf ls;
      busyPaths = lib.unique (map (g: if g == null then "none" else builtins.head g) guards);
      conf = h.xdg.configFile."hypr/hypridle.conf".text;
      lockPkgOk = builtins.any (p: "${p}/bin/universal-lock" == s.general.lock_cmd) h.home.packages;
      cmdAfter = i: let g = guardOf (builtins.elemAt ls i); in if g == null then "" else builtins.elemAt g 1;
    in
    if builtins.length ls != 3 then [ "expected 3 listeners, got ${toString (builtins.length ls)}" ] else
    (lib.optional (builtins.any (g: g == null) guards) "a listener on-timeout is not '<nix-busy> && exit 0; <command>'")
    ++ (lib.optional (builtins.length busyPaths != 1) "listeners use different guards: ${builtins.toJSON busyPaths}")
    ++ (map (cmd: "on-timeout command after the guard is empty or starts with exit: ${cmd}") (builtins.filter (cmd: cmd == "" || lib.hasPrefix "exit" cmd) (map (g: if g == null then "" else builtins.elemAt g 1) guards)))
    ++ (lib.optional (!(lib.hasInfix "brightnessctl" (cmdAfter 0))) "dim listener does not dim")
    ++ (lib.optional (cmdAfter 1 != "loginctl lock-session") "lock listener runs '${cmdAfter 1}', expected loginctl lock-session")
    ++ (lib.optional (!(lib.hasInfix "\"off\"" (cmdAfter 2))) "screen-off listener does not switch dpms off")
    ++ (lib.optional (builtins.any (l: lib.hasInfix "nix-busy" (l.on-resume or "")) ls) "an on-resume command is behind the busy guard")
    ++ (lib.optional ((map (l: l.timeout) ls) != [ opt.dimTimeout opt.lockTimeout opt.screenOffTimeout ]) "listener timeouts differ from the hypridle options")
    ++ (lib.optional (!((builtins.elemAt ls 0).timeout < (builtins.elemAt ls 1).timeout)) "dim timeout is not before lock timeout")
    ++ (lib.optional (!((builtins.elemAt ls 1).timeout < (builtins.elemAt ls 2).timeout)) "lock timeout is not before screen-off timeout")
    ++ (lib.optional (s.general.before_sleep_cmd != "loginctl lock-session") "before_sleep_cmd is ${s.general.before_sleep_cmd}")
    ++ (lib.optional (!lockPkgOk) "lock_cmd ${s.general.lock_cmd} is not a universal-lock package in home.packages")
    ++ (map (l: "on-timeout missing from generated hypridle.conf: ${l.on-timeout}") (builtins.filter (l: !(lib.hasInfix (builtins.unsafeDiscardStringContext l.on-timeout) (builtins.unsafeDiscardStringContext conf))) ls));

  busyScript = cfg:
    let g = guardOf (builtins.head (hm cfg).services.hypridle.settings.listener); in
    if g == null then null else
    let first = (builtins.head (hm cfg).services.hypridle.settings.listener).on-timeout; in
    builtins.substring 0 (builtins.stringLength (builtins.head g)) first;

  busyProblems = cfg:
    let
      p = busyScript cfg;
    in
    if p == null then [ "no busy script path found in the first listener" ]
    else busyBodyProblems (builtins.readFile p);

  lingerDir = "/var/lib/systemd/linger";
  persisted = cfg: map (d: d.directory) cfg.environment.persistence."/persist".directories;
  coffeeOnText = builtins.readFile "${flake.outPath}/modules/nixos/services/power/coffee/coffee-on.sh";
  staleHandling = text: lib.hasInfix "-f $LINGER_MARKER && $linger != yes" text;
  lingerProblems = cfg: onText:
    (lib.optional (!cfg.myconfig.services.impermanence.enable) "impermanence is off, the check is vacuous")
    ++ (lib.optional (!cfg.myconfig.services.coffee.enable) "coffee is off, the check is vacuous")
    ++ (lib.optional (!(builtins.elem lingerDir (persisted cfg)) && !staleHandling onText)
      "${lingerDir} is not persisted and coffee-on.sh has no stale linger marker handling");

  sddmOn = cfg: builtins.filter (n: cfg.myconfig.services.${n}.enable) [ "sddm-pixie" "sddm-astronaut" ];

  sddmExclusiveProblems = cfg:
    (lib.optional (builtins.length (sddmOn cfg) != 1) "expected exactly one sddm theme module, got ${builtins.toJSON (sddmOn cfg)}")
    ++ (map (a: "failed assertion: ${a.message}") (builtins.filter (a: !a.assertion) cfg.assertions));

  sddmProblems = cfg:
    let
      expectTheme = if sddmOn cfg == [ "sddm-pixie" ] then "pixie" else "sddm-astronaut-theme";
    in
    sddmExclusiveProblems cfg
    ++ (lib.optional (!cfg.services.displayManager.sddm.enable) "services.displayManager.sddm.enable is false")
    ++ (lib.optional (cfg.services.displayManager.sddm.theme != expectTheme) "sddm theme is ${cfg.services.displayManager.sddm.theme}, expected ${expectTheme}")
    ++ (lib.optional (!(builtins.elem "/var/lib/sddm" (persisted cfg))) "/var/lib/sddm is not persisted");

  wmsOff = {
    myconfig.programs.hyprland.enable = mk false;
    myconfig.programs.niri.enable = mk false;
    myconfig.programs.mango.enable = mk false;
  };
  hyprOnly = shell: [
    {
      myconfig.programs.hyprland.enable = mk true;
      myconfig.programs.niri.enable = mk false;
      myconfig.programs.mango.enable = mk false;
      myconfig.programs.noctalia.enable = mk shell;
      myconfig.programs.noctalia.enableOnHyprland = mk shell;
      myconfig.programs.caelestia.enable = mk false;
    }
  ];

  lockProblems = cfg: wmExpected:
    let has = cfg.security.pam.services ? hyprlock; in
    (lib.optional (wmExpected && !has) "security.pam.services.hyprlock missing with a WM enabled")
    ++ (lib.optional (!wmExpected && has) "security.pam.services.hyprlock present with no WM enabled");

  swayncProblems = cfg: expected:
    let e = (hm cfg).services.swaync.enable; in
    lib.optional (e != expected) "services.swaync.enable is ${builtins.toJSON e}, expected ${builtins.toJSON expected}";

  noWm = twin [ wmsOff ];
  hyprPlain = twin (hyprOnly false);
  hyprShell = twin (hyprOnly true);
  noLinger = twin [{ environment.persistence."/persist".directories = over [ ]; }];
  bothSddm = twin [{
    myconfig.services.sddm-pixie.enable = mk true;
    myconfig.services.sddm-astronaut.enable = mk true;
  }];
  noSddm = twin [{
    myconfig.services.sddm-pixie.enable = mk false;
    myconfig.services.sddm-astronaut.enable = mk false;
  }];
  unguarded = twin [{
    home-manager.users.${c.myconfig.constants.user}.services.hypridle.settings.listener = over [
      { timeout = 1; on-timeout = "loginctl lock-session"; }
      { timeout = 2; on-timeout = "loginctl lock-session"; }
      { timeout = 3; on-timeout = "loginctl lock-session"; }
    ];
  }];

  checks = {
    "hypridle: three guarded listeners, ordered timeouts matching the options, lock chain consistent" = failIf (idleProblems c);
    "hypridle: busy guard script returns pgrep's status (on-timeout reached when not busy)" = failIf (busyProblems c);
    "control(hypridle): unguarded listeners are detected" = detects "no guard" (idleProblems unguarded);
    "control(busy): '|| true' body is detected" = detects "|| true" (busyBodyProblems "#!/bin/bash\npgrep -f 'nix.build|nixos-rebuild' > /dev/null || true\n");
    "control(busy): explicit exit 0 is detected" = detects "exit 0" (busyBodyProblems "#!/bin/bash\npgrep -f 'nix.build|nixos-rebuild' > /dev/null\nexit 0\n");
    "control(busy): body without pgrep is detected" = detects "no pgrep" (busyBodyProblems "#!/bin/bash\ntrue\n");
    "coffee: linger dir persisted, or coffee-on.sh handles a stale linger marker" = failIf (lingerProblems c coffeeOnText);
    "control(coffee): unpersisted linger without stale handling is detected" = detects "no persistence" (lingerProblems noLinger "nothing");
    "control(coffee): stale marker handling in coffee-on.sh is what makes an unpersisted linger acceptable" = failIf (lingerProblems noLinger coffeeOnText);
    "hyprlock: pam service present with a WM enabled" = failIf (lockProblems hyprPlain true);
    "hyprlock: pam service absent with no WM enabled" = failIf (lockProblems noWm false);
    "control(hyprlock): WM-less twin trips the WM-expected check" = detects "missing pam" (lockProblems noWm true);
    "swaync: runs when hyprland has no shell" = failIf (swayncProblems hyprPlain true);
    "swaync: off when noctalia drives notifications on hyprland" = failIf (swayncProblems hyprShell false);
    "control(swaync): the shell twin trips the swaync-expected check" = detects "swaync off" (swayncProblems hyprShell true);
    "sddm: exactly one theme module, sddm enabled, matching theme, state persisted, no failed assertion" = failIf (sddmProblems c);
    "control(sddm): both theme modules enabled is detected" = detects "both" (sddmExclusiveProblems bothSddm);
    "control(sddm): no theme module is detected" = detects "none" (sddmExclusiveProblems noSddm);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
