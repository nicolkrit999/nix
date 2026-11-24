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

  twin = monitors: gnome: fx.mkNixos [{
    myconfig.programs.gnome.enable = mk gnome;
    myconfig.programs.gnome.monitors = mk monitors;
  }];

  etcOf = t: t.config.environment.etc."xdg/monitors.xml" or null;
  xmlOf = t: let e = etcOf t; in if e == null then null else e.text;

  id = n: { vendor = "TST"; product = "Panel ${n}"; serial = "SER-${n}"; };
  fallback = { output = "*"; };
  a = { output = "DP-A"; width = 2560; height = 1440; refresh = 144; scale = 1.5; x = 0; y = 0; primary = true; } // id "A";
  b = { output = "DP-B"; width = 1920; height = 1080; refresh = 59.94; x = 2560; y = 0; transform = 90; } // id "B";
  c = { output = "DP-C"; width = 1920; height = 1080; refresh = 60; x = 0; y = 1440; transform = 180; } // id "C";
  d = { output = "DP-D"; width = 1280; height = 720; refresh = 75; x = 3640; y = 0; transform = 270; } // id "D";
  r = { output = "HDMI-A-9"; width = 1920; height = 1080; refresh = 50; mirror = "DP-A"; } // id "R";
  off = { output = "HDMI-A-8"; enable = false; } // id "O";

  withDefaults = m: { width = 0; height = 0; refresh = 0; scale = 1.0; x = 0; y = 0; transform = 0; enable = true; mirror = ""; primary = false; } // m;

  rotName = { "0" = "normal"; "90" = "left"; "180" = "upside_down"; "270" = "right"; };
  spec = m: "<monitorspec><connector>${m.output}</connector><vendor>${m.vendor}</vendor><product>${m.product}</product><serial>${m.serial}</serial></monitorspec>";
  mon = m: w: h: rt: "<monitor>${spec m}<mode><width>${toString w}</width><height>${toString h}</height><rate>${toString rt}</rate></mode></monitor>";
  logical = prim: reps: m:
    let
      mons =
        if reps == [ ] then mon m m.width m.height m.refresh
        else
          let f = lib.head reps; in
          mon m f.width f.height f.refresh + lib.concatMapStrings (q: mon q q.width q.height q.refresh) reps;
    in
    "<logicalmonitor><x>${toString m.x}</x><y>${toString m.y}</y><scale>${toString m.scale}</scale>${mons}<transform><rotation>${rotName.${toString m.transform}}</rotation><flipped>no</flipped></transform>${if m.output == prim then "<primary>yes</primary>" else ""}</logicalmonitor>";
  predict = raw:
    let
      ms = map withDefaults (lib.filter (m: m.output != "*") raw);
      replicas = lib.filter (m: m.enable && m.mirror != "") ms;
      sources = lib.filter (m: m.enable && m.mirror == "") ms;
      disabled = lib.filter (m: !m.enable) ms;
      marked = lib.filter (m: m.primary) sources;
      prim = (lib.head (if marked != [ ] then marked else sources)).output;
      dis = "<disabled>${lib.concatMapStrings spec disabled}</disabled>";
      conf = full: "<configuration><layoutmode>logical</layoutmode>${lib.concatMapStrings (m: logical prim (if full then lib.filter (q: q.mirror == m.output) replicas else [ ]) m) sources}${if full && disabled != [ ] then dis else ""}</configuration>";
    in
    "<monitors version=\"2\">${conf true}${lib.optionalString (replicas != [ ] || disabled != [ ]) (conf false)}</monitors>\n";

  single = { output = "DP-S"; width = 1920; height = 1080; refresh = 60; primary = true; } // id "S";
  singleLiteral =
    "<monitors version=\"2\"><configuration><layoutmode>logical</layoutmode><logicalmonitor><x>0</x><y>0</y><scale>1.000000</scale>"
    + "<monitor><monitorspec><connector>DP-S</connector><vendor>TST</vendor><product>Panel S</product><serial>SER-S</serial></monitorspec>"
    + "<mode><width>1920</width><height>1080</height><rate>60</rate></mode></monitor>"
    + "<transform><rotation>normal</rotation><flipped>no</flipped></transform><primary>yes</primary></logicalmonitor></configuration></monitors>\n";

  firstDiff = got: want:
    let n = lib.findFirst (i: builtins.substring i 1 got != builtins.substring i 1 want) 0 (lib.range 0 (lib.max (builtins.stringLength got) (builtins.stringLength want)));
    in "differs at char ${toString n}: got '${builtins.substring n 60 got}' want '${builtins.substring n 60 want}'";
  xmlProblems = t: want:
    let got = xmlOf t; in
    if got == null then [ "no monitors.xml" ]
    else lib.optional (got != want) (firstDiff got want);

  failing = t: map (x: x.message) (lib.filter (x: !x.assertion) t.config.assertions);
  monitorFailing = t: lib.filter (m: lib.hasPrefix "programs.gnome.monitors:" m) (failing t);
  onlyFailing = infix: t:
    let f = monitorFailing t; in
    if builtins.length f == 1 && lib.hasInfix infix (lib.head f) then ok
    else "FAIL: expected exactly one failing monitors assertion containing \"${infix}\", got [${lib.concatStringsSep " | " f}]";

  warnsOf = t: lib.filter (m: lib.hasPrefix "programs.gnome.monitors:" m) t.config.warnings;
  onlyWarning = infix: t:
    let w = warnsOf t; in
    if builtins.length w == 1 && lib.hasInfix infix (lib.head w) && etcOf t == null then ok
    else "FAIL: expected one warning containing \"${infix}\" and no file, got [${lib.concatStringsSep " | " w}] file=${toString (etcOf t != null)}";
  primaryWarning = infix: pred: t:
    let w = warnsOf t; in
    if builtins.length w == 1 && lib.hasInfix infix (lib.head w) && xmlOf t == pred then ok
    else "FAIL: expected one warning containing \"${infix}\" and the fallback primary, got [${lib.concatStringsSep " | " w}]";
  anyFailing = infix: t:
    if lib.any (lib.hasInfix infix) (monitorFailing t) then ok
    else "FAIL: no failing monitors assertion containing \"${infix}\"";

  msFull = [ a b c d r off fallback ];
  tFull = twin msFull true;
  tSingle = twin [ single ] true;
  tFb = twin [ fallback ] true;
  tEmpty = twin [ ] true;
  tOff = twin msFull false;
  tAllOff = twin [ off ] true;
  tIncomplete = twin [ (a // { vendor = ""; }) (b // { product = ""; }) (c // { serial = ""; }) (d // { refresh = 0; }) ] true;
  tIncomplete2 = twin [ a (r // { serial = ""; }) (off // { vendor = ""; }) ] true;
  msSeveral = [ (a // { primary = false; }) (b // { primary = true; }) (c // { primary = true; }) ];
  tSeveral = twin msSeveral true;
  tReplicaPrimary = twin [ a (r // { primary = true; }) ] true;
  tOvRot = twin [ a (b // { x = 1700; y = 0; transform = 90; }) ] true;
  tOvPlain = twin [ a (b // { x = 1700; y = 0; transform = 0; }) ] true;
  tOvOk = twin [ a (b // { x = 1710; y = 0; transform = 90; }) (off // { x = 0; y = 0; }) ({ output = "DP-E"; width = 1000; height = 500; refresh = 60; x = 0; y = 960; } // id "E") ] true;
  tSameSize = twin [ a r (r // { output = "HDMI-A-7"; } // id "R2") ] true;
  tBad = twin [
    a
    r
    (r // { output = "HDMI-A-7"; width = 1280; height = 720; } // id "R2")
    (b // { mirror = "DP-9"; })
    (c // { mirror = "DP-C"; })
    ({ output = "DP-Y"; width = 800; height = 600; refresh = 60; mirror = "DP-A; rm"; } // id "Y")
    (d // { output = "DP D"; scale = 0; })
    a
    fallback
    fallback
  ]
    true;

  count = needle: s: builtins.length (lib.splitString needle s) - 1;

  desktop = flake.nixosConfigurations.nixos-desktop;
  dm = desktop.config.myconfig.programs.gnome.monitors;
  dOut = n: lib.findFirst (m: m.output == n) null dm;
  dXml = xmlOf desktop;
  dpr = dOut "DP-1";
  hdmi = dOut "HDMI-A-1";

  checks = {
    "xml: one primary monitor equals the spelled-out literal" = failIf (xmlProblems tSingle singleLiteral);
    "xml: the predictor reproduces that literal" =
      failIf (lib.optional (predict [ single ] != singleLiteral) "predictor drifted from the literal");
    "xml: four rotations, scale, mirror replica, disabled output and fallback equal the prediction" = failIf (xmlProblems tFull (predict msFull));
    "xml: float formatting is pinned (scale 1.5, refresh 59.94)" =
      failIf (map (s: "missing ${s}") (lib.filter (s: !(lib.hasInfix s (xmlOf tFull))) [ "<scale>1.500000</scale>" "<rate>59.940000</rate>" "<rate>144</rate>" ]));
    "xml: all four transform names present" =
      failIf (map (s: "missing ${s}") (lib.filter (s: !(lib.hasInfix s (xmlOf tFull))) [ "<rotation>normal</rotation>" "<rotation>left</rotation>" "<rotation>upside_down</rotation>" "<rotation>right</rotation>" ]));
    "xml: two configurations, replica and disabled block only in the first" =
      let x = xmlOf tFull; in
      failIf (lib.optional (count "<configuration>" x != 2) "not two configurations"
        ++ lib.optional (count "<connector>HDMI-A-9</connector>" x != 1) "replica not exactly once"
        ++ lib.optional (count "<disabled>" x != 1) "disabled block not exactly once"
        ++ lib.optional (count "<layoutmode>logical</layoutmode>" x != 2) "layoutmode not in both configurations"
        ++ lib.optional (count "<primary>yes</primary>" x != 2) "primary not once per configuration");
    "xml: replica shares the source logical monitor, the source takes the replica mode size" =
      let
        first = lib.head (lib.splitString "</configuration>" (xmlOf tFull));
        second = lib.elemAt (lib.splitString "</configuration>" (xmlOf tFull)) 1;
      in
      failIf (lib.optional (!(lib.hasInfix "<connector>HDMI-A-9</connector>" first)) "replica missing in the mirrored configuration"
        ++ lib.optional (lib.hasInfix "<width>2560</width>" first) "source kept its own 2560 mode in the mirrored configuration"
        ++ lib.optional (count "<width>1920</width><height>1080</height>" first != 4) "source, replica, DP-B and DP-C modes do not line up"
        ++ lib.optional (!(lib.hasInfix "<width>2560</width><height>1440</height><rate>144</rate>" second)) "source lost its own mode in the plain configuration");
    "xml: fallback-only, empty list: no file" =
      if etcOf tFb == null && etcOf tEmpty == null then ok else "FAIL: monitors.xml present for fallback-only or empty list";
    "xml: gnome disabled: no file even with monitors declared" =
      if etcOf tOff == null then ok else "FAIL: monitors.xml present with gnome off";
    "xml: only disabled outputs: no file, one warning" = onlyWarning "no enabled non-mirrored output" tAllOff;
    "xml: control, wrong rotation is detected" = detects "wrong rotation" (xmlProblems tFull (predict [ a (b // { transform = 270; }) c d r off ]));
    "xml: control, a dropped mirror is detected" = detects "dropped mirror" (xmlProblems tFull (predict [ a b c d (r // { mirror = ""; enable = false; }) off ]));
    "xml: control, a different primary is detected" = detects "primary moved" (xmlProblems tFull (predict [ (a // { primary = false; }) (b // { primary = true; }) c d r off ]));
    "xml: control, a changed serial is detected" = detects "serial" (xmlProblems tFull (predict [ (a // { serial = "other"; }) b c d r off ]));
    "xml: control, an absent file against a prediction is detected" = detects "absent file" (xmlProblems tFb (predict msFull));

    "assert: valid twins raise no monitors assertion or warning" = failIf (lib.concatMap monitorFailing [ tFull tSingle tFb ] ++ lib.concatMap warnsOf [ tFull tSingle tFb ]);
    "incomplete: missing vendor, product, serial or mode on any output warns, names every one, writes nothing" =
      onlyWarning "DP-A, DP-B, DP-C, DP-D are incomplete" tIncomplete;
    "incomplete: an incomplete replica or an identity-less disabled output blocks the whole file" =
      onlyWarning "HDMI-A-9, HDMI-A-8 are incomplete" tIncomplete2;
    "incomplete: incomplete input raises no assertion" = failIf (monitorFailing tIncomplete ++ monitorFailing tIncomplete2);
    "primary: none marked falls back to the first enabled non-mirrored output" =
      primaryWarning "using DP-A" (predict [ a b ]) (twin [ (a // { primary = false; }) b ] true);
    "primary: several marked uses the first marked one" =
      primaryWarning "using DP-B" (predict msSeveral) tSeveral;
    "primary: no warning and no assertion with exactly one" = failIf (warnsOf tFull ++ monitorFailing tFull);
    "primary: a flag on a replica has no effect" =
      failIf (lib.optional (monitorFailing tReplicaPrimary != [ ] || warnsOf tReplicaPrimary != [ ]) "assertion or warning raised" ++ xmlProblems tReplicaPrimary (predict [ a r ]));
    "overlap: overlapping outputs are rejected, rotation swaps width and height (x=1700 rotated collides)" = onlyFailing "must not overlap" tOvRot;
    "overlap: overlapping outputs are rejected without rotation too" = onlyFailing "must not overlap" tOvPlain;
    "overlap: scale shrinks the rectangle (x=1710 clears 2560/1.5), rotation, a disabled output at 0,0 never overlaps, exactly adjacent outputs are accepted" =
      failIf (monitorFailing tOvOk ++ warnsOf tOvOk);
    "assert: replicas of one source with different sizes" = anyFailing "share width and height" tBad;
    "xml: two replicas of one source share one logical monitor" =
      let first = lib.head (lib.splitString "</configuration>" (xmlOf tSameSize)); in
      failIf (lib.optional (xmlOf tSameSize == null) "no file"
        ++ lib.optional (xmlOf tSameSize != null && (count "<logicalmonitor>" first != 1 || count "<monitor>" first != 3)) "not one logical monitor with three monitors");
    "assert: replicas of one source with the same size are accepted" = failIf (monitorFailing tSameSize);
    "assert: mirror of an undeclared source" = anyFailing "mirror source must" tBad;
    "assert: output mirroring itself" = anyFailing "cannot mirror itself" tBad;
    "assert: duplicate output names" = anyFailing "unique" tBad;
    "assert: two fallback entries" = anyFailing "at most one" tBad;
    "assert: bad characters in a mirror name" = anyFailing "mirror names may only" tBad;
    "assert: scale 0" = anyFailing "scale must" tBad;
    "assert: bad characters in an output name" = anyFailing "output names may only" tBad;
    "assert: control, the reader sees nothing on a valid twin and something on a bad one" =
      failIf (lib.optional (monitorFailing tFull != [ ]) "valid twin flagged"
        ++ lib.optional (monitorFailing tOvPlain == [ ]) "bad twin not flagged");

    "real desktop: DP-1 primary 4K, DP-2, HDMI-A-1 disabled without mirror, no DP-3" =
      failIf (lib.optional (dpr == null || dOut "DP-2" == null || hdmi == null) "an output is missing"
        ++ lib.optional (dpr != null && !(dpr.primary && dpr.width == 3840 && dpr.height == 2160)) "DP-1 is not the primary 4K output"
        ++ lib.optional (hdmi != null && (hdmi.enable || hdmi.mirror != "")) "HDMI-A-1 is neither disabled nor free of a mirror"
        ++ lib.optional (dOut "DP-3" != null) "DP-3 is declared"
        ++ lib.optional (lib.any (m: m.mirror != "") dm) "some output mirrors");
    "real desktop: monitors.xml equals the prediction from its own monitors" =
      failIf (if dXml == null then [ "no monitors.xml" ] else lib.optional (dXml != predict dm) (firstDiff dXml (predict dm)));
    "real desktop: two configurations, HDMI-A-1 only in the disabled block of the first, no DP-3" =
      let
        x = if dXml == null then "" else dXml;
        parts = lib.splitString "</configuration>" x;
      in
      failIf (lib.optional (dXml == null) "no monitors.xml"
        ++ lib.optional (count "<configuration>" x != 2) "not exactly two configurations"
        ++ lib.optional (count "<connector>HDMI-A-1</connector>" x != 1) "HDMI-A-1 not exactly once"
        ++ lib.optional (!(lib.hasInfix "<disabled><monitorspec><connector>HDMI-A-1</connector>" (lib.head parts))) "HDMI-A-1 not in the disabled block of the first configuration"
        ++ lib.optional (lib.hasInfix "<connector>DP-3</connector>" x) "DP-3 in the file"
        ++ lib.optional (count "<rate>240</rate>" x != 2) "DP-1 not at its own 240 Hz mode in both configurations"
        ++ lib.optional (count "<primary>yes</primary>" x != 2) "primary not once per configuration");
    "real desktop: no monitors assertion fails and no monitors warning" = failIf (monitorFailing desktop ++ warnsOf desktop);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
