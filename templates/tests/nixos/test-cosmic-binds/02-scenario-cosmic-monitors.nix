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

  twin = monitors: cosmic: fx.mkNixos [{
    myconfig.programs.cosmic.enable = mk cosmic;
    myconfig.programs.cosmic.monitors = mk monitors;
  }];

  fallback = { output = "*"; };
  dp1 = { output = "DP-1"; width = 3840; height = 2160; refresh = 240; scale = 1.5; x = 1440; y = 560; };
  dp2 = { output = "DP-2"; width = 3840; height = 2160; refresh = 144; scale = 1.5; x = 0; y = 0; transform = 90; };
  hdmi = { output = "HDMI-A-1"; enable = false; };

  hmOf = fx.hmOf;
  planFile = t: (hmOf t).xdg.configFile."cosmic-monitors/plan" or null;
  planText = t: (planFile t).text;
  serviceOf = t: (hmOf t).systemd.user.services.cosmic-monitors or null;

  num = n: if builtins.isFloat n && n == builtins.floor n then toString (builtins.floor n) else builtins.toJSON n;
  rot = { "0" = "normal"; "90" = "rotate90"; "180" = "rotate180"; "270" = "rotate270"; };
  withDefaults = m: { width = 0; height = 0; refresh = 0; scale = 1.0; x = 0; y = 0; transform = 0; enable = true; } // m;
  predictLine = raw:
    let m = withDefaults raw; in
    if !m.enable then "disable ${m.output}"
    else "mode ${m.output} ${num m.width} ${num m.height} --refresh ${num m.refresh} --scale ${num m.scale} --transform ${rot.${num m.transform}} --pos-x ${num m.x} --pos-y ${num m.y}";
  predictPlan = ms: map predictLine (lib.filter (m: m.output != "*") ms);

  linesOf = text:
    let parts = lib.splitString "\n" text; in
    if lib.last parts == "" then lib.init parts else parts ++ [ "<no trailing newline>" ];
  sorted = lib.sort (a: b: a < b);
  planProblems = t: pred:
    let
      f = planFile t;
      got = if f == null then [ ] else linesOf f.text;
      miss = lib.filter (l: !(lib.elem l got)) pred;
      extra = lib.filter (l: !(lib.elem l pred)) got;
    in
    (if f == null && pred != [ ] then [ "no plan file, expected ${toString (builtins.length pred)} lines" ] else [ ])
    ++ map (l: "missing: ${l}") miss
    ++ map (l: "unexpected: ${l}") extra
    ++ lib.optional (lib.length got != lib.length pred) "line count ${toString (lib.length got)} != ${toString (lib.length pred)}"
    ++ lib.optional (sorted got != sorted pred) "line sets differ";

  failing = t: map (a: a.message) (lib.filter (a: !a.assertion) t.config.assertions);
  monitorFailing = t: lib.filter (m: lib.hasPrefix "programs.cosmic.monitors:" m) (failing t);
  onlyFailing = infix: t:
    let f = monitorFailing t; in
    if builtins.length f == 1 && lib.hasInfix infix (lib.head f) then ok
    else "FAIL: expected exactly one failing monitors assertion containing \"${infix}\", got [${lib.concatStringsSep " | " f}]";

  anyFailing = infix: t:
    if lib.any (lib.hasInfix infix) (monitorFailing t) then ok
    else "FAIL: no failing monitors assertion containing \"${infix}\"";

  msA = [ dp1 dp2 hdmi fallback ];
  msB = [ fallback ];
  msC = [
    { output = "DP-3"; width = 2560; height = 1440; refresh = 143.999; scale = 1.25; x = -1920; y = 0; transform = 180; }
    { output = "HDMI-A-2"; width = 1920; height = 1080; refresh = 59.94; scale = 2.0; x = 3000; y = -100; transform = 270; }
    { output = "eDP-1"; width = 1280; height = 800; refresh = 60; x = 7; y = 9; }
  ];
  msOnlyDisabled = [ hdmi { output = "DP-9"; enable = false; } ];

  tA = twin msA true;
  tB = twin msB true;
  tC = twin msC true;
  tD = twin msOnlyDisabled true;
  tOff = twin msA false;

  tDup = twin [ dp1 dp1 ] true;
  tTwoStar = twin [ dp1 fallback fallback ] true;
  tNoW = twin [ (dp1 // { width = 0; }) ] true;
  tNoH = twin [ (removeAttrs dp1 [ "height" ]) ] true;
  tNoR = twin [ (dp1 // { refresh = 0; }) ] true;
  tScale = twin [ (dp1 // { scale = 0; }) ] true;
  tMeta = twin [ (dp1 // { output = "DP-1; rm -rf"; }) ] true;
  tSpace = twin [ (dp1 // { output = "DP 1"; }) ] true;
  tDisabledBare = twin [ hdmi ] true;

  svcProblems = t:
    let
      s = serviceOf t;
      get = path: lib.attrByPath path null s;
      getL = path: lib.attrByPath path [ ] s;
    in
    if s == null then [ "no cosmic-monitors service" ] else
    lib.optional (get [ "Service" "Type" ] != "oneshot") "Type is not oneshot"
    ++ lib.optional (get [ "Service" "RemainAfterExit" ] != true) "RemainAfterExit is not true"
    ++ lib.optional (!(lib.hasSuffix "is-cosmic-session" (toString (get [ "Service" "ExecCondition" ])))) "ExecCondition is not the is-cosmic-session script"
    ++ lib.optional (!(lib.elem "graphical-session.target" (getL [ "Install" "WantedBy" ]))) "not WantedBy graphical-session.target"
    ++ lib.optional (!(lib.elem "graphical-session.target" (getL [ "Unit" "PartOf" ]))) "not PartOf graphical-session.target"
    ++ lib.optional (!(lib.elem "graphical-session.target" (getL [ "Unit" "After" ]))) "not After graphical-session.target";

  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;
  monitorsOf = h: h.config.myconfig.programs.cosmic.monitors;
  byName = ms: n: lib.findFirst (m: m.output == n) null ms;
  expect = ms: n: want:
    let m = byName ms n; in
    if m == null then [ "${n} missing" ]
    else lib.concatMap (k: lib.optional (m.${k} != want.${k}) "${n}.${k} is ${builtins.toJSON m.${k}}, expected ${builtins.toJSON want.${k}}") (builtins.attrNames want);
  fallbacks = ms: lib.filter (m: m.output == "*") ms;

  dm = monitorsOf desktop;
  lm = monitorsOf laptop;
  dHm = hmOf desktop;

  checks = {
    "plan: 2 enabled (one rotated) + disabled + fallback equals the independent prediction" = failIf (planProblems tA (predictPlan msA));
    "plan: the prediction for that twin is the three expected lines" =
      failIf (lib.optional
        (predictPlan msA != [
          "mode DP-1 3840 2160 --refresh 240 --scale 1.5 --transform normal --pos-x 1440 --pos-y 560"
          "mode DP-2 3840 2160 --refresh 144 --scale 1.5 --transform rotate90 --pos-x 0 --pos-y 0"
          "disable HDMI-A-1"
        ]) "prediction drifted from the spelled-out lines");
    "plan: fallback entry produces no line" =
      failIf (lib.optional (lib.any (lib.hasInfix "*") (linesOf (planText tA))) "a plan line mentions *");
    "plan: non-integer refresh, negative positions, rotations 180/270, float scale" = failIf (planProblems tC (predictPlan msC));
    "plan: 143.999 survives without rounding" =
      failIf (lib.optional (!(lib.elem "mode DP-3 2560 1440 --refresh 143.999 --scale 1.25 --transform rotate180 --pos-x -1920 --pos-y 0" (linesOf (planText tC)))) "exact 143.999 line missing");
    "plan: only disabled outputs gives only disable lines" = failIf (planProblems tD (predictPlan msOnlyDisabled));
    "plan: only the fallback gives no plan file" =
      if planFile tB == null then ok else "FAIL: plan file present for a fallback-only list";
    "plan: only the fallback gives no service" =
      if serviceOf tB == null then ok else "FAIL: service present for a fallback-only list";
    "plan: control, a changed refresh in the prediction is detected" =
      detects "wrong refresh" (planProblems tA (predictPlan [ (dp1 // { refresh = 239; }) dp2 hdmi ]));
    "plan: control, a wrong rotation mapping is detected" =
      detects "wrong rotation" (planProblems tA (predictPlan [ dp1 (dp2 // { transform = 270; }) hdmi ]));
    "plan: control, a prediction missing the disable line is detected" =
      detects "missing disable" (planProblems tA (predictPlan [ dp1 dp2 ]));
    "plan: control, an extra predicted line is detected" =
      detects "extra line" (planProblems tA (predictPlan (msA ++ [{ output = "DP-7"; enable = false; }])));
    "plan: control, a fallback-only twin against a non-empty prediction is detected" =
      detects "plan expected but absent" (planProblems tB (predictPlan msA));

    "assert: valid twins raise no monitors assertion" =
      failIf (lib.concatMap monitorFailing [ tA tB tC tD tDisabledBare ]);
    "assert: duplicate output names" = onlyFailing "unique" tDup;
    "assert: two \"*\" fallbacks" = anyFailing "at most one" tTwoStar;
    "assert: enabled output without width" = onlyFailing "width, height and refresh" tNoW;
    "assert: enabled output without height" = onlyFailing "width, height and refresh" tNoH;
    "assert: enabled output without refresh" = onlyFailing "width, height and refresh" tNoR;
    "assert: scale 0" = onlyFailing "scale must" tScale;
    "assert: shell metacharacters in an output name" = onlyFailing "letters, digits" tMeta;
    "assert: space in an output name" = onlyFailing "letters, digits" tSpace;
    "assert: a disabled output needs no mode values" =
      failIf (monitorFailing tDisabledBare);
    "assert: control, the failure reader sees nothing on a valid twin and something on a bad one" =
      failIf (lib.optional (monitorFailing tA != [ ]) "valid twin flagged" ++ lib.optional (monitorFailing tDup == [ ]) "bad twin not flagged");

    "service: defined for a plan with cosmic enabled, oneshot, RemainAfterExit, ExecCondition, graphical-session wiring" = failIf (svcProblems tA);
    "service: also defined when only disabled outputs are declared" = failIf (svcProblems tD);
    "service: absent with cosmic disabled even with monitors declared" =
      if serviceOf tOff == null then ok else "FAIL: service present with cosmic off";
    "service: plan file absent with cosmic disabled" =
      if planFile tOff == null then ok else "FAIL: plan file present with cosmic off";
    "service: control, the checker flags a missing service" = detects "missing service" (svcProblems tB);

    "real desktop: DP-1 3840x2160@240 scale 1.5 at 1440,560 unrotated" =
      failIf (expect dm "DP-1" { width = 3840; height = 2160; refresh = 240; scale = 1.5; x = 1440; y = 560; transform = 0; enable = true; });
    "real desktop: DP-2 3840x2160@144 scale 1.5 at 0,0 rotated 90" =
      failIf (expect dm "DP-2" { width = 3840; height = 2160; refresh = 144; scale = 1.5; x = 0; y = 0; transform = 90; enable = true; });
    "real desktop: HDMI-A-1 disabled" = failIf (expect dm "HDMI-A-1" { enable = false; });
    "real desktop: exactly one \"*\" fallback and four entries" =
      failIf (lib.optional (builtins.length (fallbacks dm) != 1) "fallback count ${toString (builtins.length (fallbacks dm))}"
        ++ lib.optional (builtins.length dm != 4) "entry count ${toString (builtins.length dm)}");
    "real desktop: generated plan is the three expected lines" =
      failIf (
        let f = dHm.xdg.configFile."cosmic-monitors/plan" or null; in
        if f == null then [ "no plan file" ] else
        let got = linesOf f.text; in
        lib.optional
          (got != [
            "mode DP-1 3840 2160 --refresh 240 --scale 1.5 --transform normal --pos-x 1440 --pos-y 560"
            "mode DP-2 3840 2160 --refresh 144 --scale 1.5 --transform rotate90 --pos-x 0 --pos-y 0"
            "disable HDMI-A-1"
          ]) "plan lines are [${lib.concatStringsSep " | " got}]"
      );
    "real desktop: plan equals the independent prediction from its own monitors" =
      failIf (
        let f = dHm.xdg.configFile."cosmic-monitors/plan" or null; in
        if f == null then [ "no plan file" ] else
        let
          pred = predictPlan dm;
          got = linesOf f.text;
        in
        lib.optional (sorted got != sorted pred) "plan [${lib.concatStringsSep " | " got}] != prediction [${lib.concatStringsSep " | " pred}]"
      );
    "real desktop: cosmic-monitors service defined" =
      failIf (if dHm.systemd.user.services ? cosmic-monitors then [ ] else [ "no cosmic-monitors service" ]);
    "real desktop: no monitors assertion fails" = failIf (monitorFailing desktop);
    "real laptop: eDP-1 3200x2000@120 scale 1.0 at 0,0" =
      failIf (expect lm "eDP-1" { width = 3200; height = 2000; refresh = 120; scale = 1.0; x = 0; y = 0; transform = 0; enable = true; });
    "real laptop: exactly one \"*\" fallback and two entries" =
      failIf (lib.optional (builtins.length (fallbacks lm) != 1) "fallback count ${toString (builtins.length (fallbacks lm))}"
        ++ lib.optional (builtins.length lm != 2) "entry count ${toString (builtins.length lm)}");
    "real laptop: plan derived from its monitors is the single eDP-1 line" =
      failIf (lib.optional (predictPlan lm != [ "mode eDP-1 3200 2000 --refresh 120 --scale 1 --transform normal --pos-x 0 --pos-y 0" ]) "prediction [${lib.concatStringsSep " | " (predictPlan lm)}]");
    "real hosts: control, the expectation helper flags a wrong value and a missing output" =
      detects "wrong expectation" (expect dm "DP-1" { refresh = 241; } ++ expect dm "DP-99" { enable = true; });
    "real hosts: every declared output name is accepted by the name rule" =
      failIf (map (m: "bad name ${m.output}") (lib.filter (m: m.output != "*" && builtins.match "[A-Za-z0-9_.:-]+" m.output == null) (dm ++ lm)));
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
