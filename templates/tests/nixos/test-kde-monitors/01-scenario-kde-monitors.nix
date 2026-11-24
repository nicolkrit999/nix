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

  twin = monitors: kde: fx.mkNixos [{
    myconfig.programs.kde.enable = mk kde;
    myconfig.programs.kde.monitors = mk monitors;
  }];

  fallback = { output = "*"; };
  edp = { output = "eDP-1"; width = 3200; height = 2000; refresh = 120; scale = 1.25; x = 0; y = 0; transform = 90; };
  dp1 = { output = "DP-1"; width = 1920; height = 1080; refresh = 59.94; x = 1600; y = -40; mirror = "eDP-1"; };
  hdmi = { output = "HDMI-A-1"; enable = false; };

  hmOf = fx.hmOf;
  planFile = t: (hmOf t).xdg.configFile."kde-monitors/plan" or null;
  serviceOf = t: (hmOf t).systemd.user.services.kde-monitors or null;

  num = n: if builtins.isFloat n && n == builtins.floor n then toString (builtins.floor n) else builtins.toJSON n;
  rot = { "0" = "none"; "90" = "left"; "180" = "inverted"; "270" = "right"; };
  withDefaults = m: { width = 0; height = 0; refresh = 0; scale = 1.0; x = 0; y = 0; transform = 0; enable = true; mirror = ""; } // m;
  predictLine = raw:
    let m = withDefaults raw; o = "output.${m.output}"; in
    if !m.enable then "${o}.disable"
    else
      lib.concatStringsSep " " [
        "${o}.enable"
        "${o}.mode.${num m.width}x${num m.height}@${num m.refresh}"
        "${o}.scale.${num m.scale}"
        "${o}.position.${num m.x},${num m.y}"
        "${o}.rotation.${rot.${num m.transform}}"
        "${o}.mirror.${if m.mirror == "" then "none" else m.mirror}"
      ];
  predictPlan = ms: map predictLine (lib.filter (m: m.output != "*") ms);

  linesOf = text:
    let parts = lib.splitString "\n" text; in
    if lib.last parts == "" then lib.init parts else parts ++ [ "<no trailing newline>" ];
  planProblems = t: pred:
    let
      f = planFile t;
      got = if f == null then [ ] else linesOf f.text;
    in
    (if f == null && pred != [ ] then [ "no plan file" ] else [ ])
    ++ map (l: "missing: ${l}") (lib.filter (l: !(lib.elem l got)) pred)
    ++ map (l: "unexpected: ${l}") (lib.filter (l: !(lib.elem l pred)) got)
    ++ lib.optional (lib.length got != lib.length pred) "line count ${toString (lib.length got)} != ${toString (lib.length pred)}";

  failing = t: map (a: a.message) (lib.filter (a: !a.assertion) t.config.assertions);
  monitorFailing = t: lib.filter (m: lib.hasPrefix "programs.kde.monitors:" m) (failing t);
  onlyFailing = infix: t:
    let f = monitorFailing t; in
    if builtins.length f == 1 && lib.hasInfix infix (lib.head f) then ok
    else "FAIL: expected exactly one failing monitors assertion containing \"${infix}\", got [${lib.concatStringsSep " | " f}]";
  anyFailing = infix: t:
    if lib.any (lib.hasInfix infix) (monitorFailing t) then ok
    else "FAIL: no failing monitors assertion containing \"${infix}\"";

  msA = [ edp dp1 hdmi fallback ];
  tA = twin msA true;
  tB = twin [ fallback ] true;
  tOff = twin msA false;

  tDup = twin [ edp edp ] true;
  tSelf = twin [ (edp // { mirror = "eDP-1"; }) ] true;
  tUndeclared = twin [ edp (dp1 // { mirror = "DP-9"; }) ] true;
  tChain = twin [ edp (dp1 // { mirror = "HDMI-A-2"; }) { output = "HDMI-A-2"; width = 1920; height = 1080; refresh = 60; mirror = "eDP-1"; } ] true;
  tMirrorChars = twin [ edp (dp1 // { mirror = "eDP-1; rm"; }) ] true;
  tOutChars = twin [ (edp // { output = "eDP 1"; }) ] true;
  tScale = twin [ (edp // { scale = 0; }) ] true;

  svcProblems = t:
    let
      s = serviceOf t;
      get = path: lib.attrByPath path null s;
    in
    if s == null then [ "no kde-monitors service" ] else
    lib.optional (get [ "Service" "Type" ] != "oneshot") "Type is not oneshot"
    ++ lib.optional (!(lib.hasSuffix "is-kde-session" (toString (get [ "Service" "ExecCondition" ])))) "ExecCondition is not the is-kde-session script"
    ++ lib.optional (!(lib.elem "graphical-session.target" (lib.attrByPath [ "Install" "WantedBy" ] [ ] s))) "not WantedBy graphical-session.target";

  desktop = flake.nixosConfigurations.nixos-desktop;
  laptop = flake.nixosConfigurations.nixos-laptop;
  lm = laptop.config.myconfig.programs.kde.monitors;
  edpLaptop = lib.findFirst (m: m.output == "eDP-1") null lm;
  dm = desktop.config.myconfig.programs.kde.monitors;
  desktopPlan = (hmOf desktop).xdg.configFile."kde-monitors/plan" or null;
  laptopPlan = (hmOf laptop).xdg.configFile."kde-monitors/plan" or null;

  checks = {
    "plan: 2 enabled (rotated + mirror replica) + disabled + fallback equals the prediction" = failIf (planProblems tA (predictPlan msA));
    "plan: the prediction is the three spelled-out lines" =
      failIf (lib.optional
        (predictPlan msA != [
          "output.eDP-1.enable output.eDP-1.mode.3200x2000@120 output.eDP-1.scale.1.25 output.eDP-1.position.0,0 output.eDP-1.rotation.left output.eDP-1.mirror.none"
          "output.DP-1.enable output.DP-1.mode.1920x1080@59.94 output.DP-1.scale.1 output.DP-1.position.1600,-40 output.DP-1.rotation.none output.DP-1.mirror.eDP-1"
          "output.HDMI-A-1.disable"
        ]) "prediction drifted from the spelled-out lines");
    "plan: fallback entry produces no line" =
      failIf (lib.optional (lib.any (lib.hasInfix "*") (linesOf (planFile tA).text)) "a plan line mentions *");
    "plan: only the fallback gives no plan file" =
      if planFile tB == null then ok else "FAIL: plan file present for a fallback-only list";
    "plan: only the fallback gives no service" =
      if serviceOf tB == null then ok else "FAIL: service present for a fallback-only list";
    "plan: option default is empty, so KDE alone gives no plan and no service" =
      let t = fx.mkNixos [{ myconfig.programs.kde.enable = mk true; }]; in
      if t.config.myconfig.programs.kde.monitors == [ ] && planFile t == null && serviceOf t == null then ok
      else "FAIL: default monitors not empty or plan/service present";
    "plan: control, a wrong rotation is detected" =
      detects "wrong rotation" (planProblems tA (predictPlan [ (edp // { transform = 270; }) dp1 hdmi ]));
    "plan: control, a dropped mirror is detected" =
      detects "wrong mirror" (planProblems tA (predictPlan [ edp (dp1 // { mirror = ""; }) hdmi ]));
    "plan: control, a missing disable line is detected" =
      detects "missing disable" (planProblems tA (predictPlan [ edp dp1 ]));
    "plan: control, a fallback-only twin against a non-empty prediction is detected" =
      detects "plan expected but absent" (planProblems tB (predictPlan msA));

    "assert: valid twins raise no monitors assertion" = failIf (lib.concatMap monitorFailing [ tA tB ]);
    "assert: duplicate output names" = onlyFailing "unique" tDup;
    "assert: output mirroring itself" = anyFailing "cannot mirror itself" tSelf;
    "assert: mirror of an undeclared source" = onlyFailing "mirror source must" tUndeclared;
    "assert: mirror of a source that itself mirrors" = onlyFailing "mirror source must" tChain;
    "assert: bad characters in a mirror name" = anyFailing "mirror names may only" tMirrorChars;
    "assert: bad characters in an output name" = onlyFailing "output names may only" tOutChars;
    "assert: scale 0" = onlyFailing "scale must" tScale;
    "assert: control, the failure reader sees nothing on a valid twin and something on a bad one" =
      failIf (lib.optional (monitorFailing tA != [ ]) "valid twin flagged" ++ lib.optional (monitorFailing tDup == [ ]) "bad twin not flagged");

    "service: oneshot, is-kde-session ExecCondition, WantedBy graphical-session.target" = failIf (svcProblems tA);
    "service: absent with kde disabled even with monitors declared" =
      if serviceOf tOff == null && planFile tOff == null then ok else "FAIL: service or plan present with kde off";
    "service: control, the checker flags a missing service" = detects "missing service" (svcProblems tB);

    "real laptop: eDP-1 3200x2000@120" =
      failIf (lib.optional (edpLaptop == null) "eDP-1 missing"
        ++ lib.optionals (edpLaptop != null) (lib.concatMap (k: lib.optional (edpLaptop.${k} != { width = 3200; height = 2000; refresh = 120; enable = true; }.${k}) "eDP-1.${k} is ${builtins.toJSON edpLaptop.${k}}") [ "width" "height" "refresh" "enable" ]));
    "real laptop: plan equals the prediction from its own monitors" =
      failIf (if laptopPlan == null then [ "no plan file" ] else lib.optional (linesOf laptopPlan.text != predictPlan lm) "plan differs from prediction");
    "real laptop: no monitors assertion fails" = failIf (monitorFailing laptop);
    "real desktop: plan equals the prediction from its own monitors, HDMI-A-1 mirrors DP-1" =
      failIf (if desktopPlan == null then [ "no plan file" ] else
      lib.optional (linesOf desktopPlan.text != predictPlan dm) "plan differs from prediction"
      ++ lib.optional (!(lib.any (l: lib.hasInfix "output.HDMI-A-1.mirror.DP-1" l) (linesOf desktopPlan.text))) "HDMI-A-1 does not mirror DP-1");
    "real desktop: no monitors assertion fails" = failIf (monitorFailing desktop);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
