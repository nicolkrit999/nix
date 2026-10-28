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
  safe = c:
    let r = builtins.tryEval (builtins.deepSeq c c);
    in if r.success then r.value else "FAIL: eval error";

  cosmicOn = { myconfig.programs.cosmic.enable = mk true; };
  withWallpapers = ws: { myconfig.constants.wallpapers = mk ws; };

  urlA = "https://example.invalid/a.jpg";
  shaA = "0w7699lvxsvflxzb0xzml3cph6fgnl8pn707822jrdsh8h8lnpxa";
  urlB = "https://example.invalid/b.jpg";
  shaB = "1p55hqqmwrvr8xbsxk2z3brb5x3y7ywsckyvlcl431i7w37j15c3";
  urlC = "https://example.invalid/c.jpg";
  shaC = "0q4simvbyvjwrzh1nv0skxygz5rdr2gfrbhmbiixj3q04k8dqfxh";
  video = "https://example.invalid/v.mp4";
  videoSha = "0g1gxwhwbg7brglwxg069ivacs33p7hmy4mn7gkz9zh4xlwrmag4";

  entry = target: url: sha: {
    targetMonitor = target;
    wallpaperURL = url;
    wallpaperSHA256 = sha;
  };
  videoOnly = target: {
    targetMonitor = target;
    videoURL = video;
    videoSHA256 = videoSha;
  };

  twin = ws: fx.mkNixos [ cosmicOn (withWallpapers ws) ];

  hmCosmic = t: (fx.hmOf t).wayland.desktopManager.cosmic;
  wallpapersOf = t: (hmCosmic t).wallpapers;
  constsOf = t: t.config.myconfig.constants;
  fetched = t: url: sha: "${t.pkgs.fetchurl { inherit url; sha256 = sha; }}";
  fallbackOf = t: fetched t (constsOf t).fallbackWallpaperURL (constsOf t).fallbackWallpaperSHA256;

  isPath = w: (w.source.__type or "") == "enum" && (w.source.variant or "") == "Path"
    && builtins.isList w.source.value && builtins.length w.source.value == 1
    && builtins.isString (lib.head w.source.value);
  pathOf = w: lib.head w.source.value;
  outputsOf = ws: map (w: w.output) ws;
  dups = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);
  safeName = n: builtins.match "[A-Za-z0-9_.:-]+" n != null;

  shapeProblems = ws:
    map (w: "bad source shape for ${w.output}") (lib.filter (w: !(isPath w)) ws)
    ++ map (o: "duplicate output ${o}") (dups (outputsOf ws))
    ++ map (o: "unsafe output name ${o}") (lib.filter (o: o != "all" && !(safeName o)) (outputsOf ws))
    ++ lib.optional (lib.elem "all" (outputsOf ws) && builtins.length ws != 1) "all mixed with per-output entries";

  expectProblems = ws: want:
    let
      got = lib.listToAttrs (map (w: { name = w.output; value = pathOf w; }) ws);
      missing = lib.filter (k: !(got ? ${k})) (builtins.attrNames want);
      unexpected = lib.filter (k: !(want ? ${k})) (builtins.attrNames got);
      wrong = lib.filter (k: got ? ${k} && want ? ${k} && got.${k} != want.${k}) (builtins.attrNames want);
    in
    shapeProblems ws
    ++ map (k: "missing ${k}") missing
    ++ map (k: "unexpected ${k}") unexpected
    ++ map (k: "${k}: ${got.${k}} != ${want.${k}}") wrong;

  failingAssertions = t: lib.filter (a: !a.assertion) t.config.assertions;
  dupAssertion = t: lib.filter (a: lib.hasInfix "Each output can only have one" a.message) (failingAssertions t);

  desktopLike = twin [
    (entry "DP-1" urlA shaA)
    (entry "DP-2" urlB shaB)
    (entry "*" urlC shaC)
  ];
  starOnly = twin [ (entry "*" urlC shaC) ];
  videoStar = twin [ (videoOnly "*") ];
  videoNamed = twin [ (videoOnly "DP-1") (entry "DP-2" urlB shaB) ];
  descMixed = twin [ (entry "desc:Foo Monitor ABC" urlA shaA) (entry "DP-1" urlB shaB) (entry "*" urlC shaC) ];
  descOnly = twin [ (entry "desc:Foo Monitor ABC" urlA shaA) (entry "*" urlC shaC) ];
  unsafeName = twin [ (entry "DP-1; touch /tmp/x" urlA shaA) (entry "HDMI-A-1" urlB shaB) ];
  emptyList = twin [ ];
  dupTwin = twin [ (entry "DP-1" urlA shaA) (entry "DP-1" urlB shaB) ];
  off = fx.mkNixos [{ myconfig.programs.cosmic.enable = mk false; } (withWallpapers [ (entry "DP-1" urlA shaA) ])];

  real = {
    desktop = flake.nixosConfigurations.nixos-desktop;
    laptop = flake.nixosConfigurations.nixos-laptop;
  };
  realProblems = t:
    let
      ws = (constsOf t).wallpapers;
      named = lib.filter (w: w.targetMonitor != "*") ws;
      got = wallpapersOf t;
    in
    if got == null then [ "wallpapers null" ]
    else
      shapeProblems got
      ++ (
        if named == [ ] then [ ]
        else
          map (w: "${w.targetMonitor} mismatch")
            (lib.filter
              (w: !(lib.any (g: g.output == w.targetMonitor && pathOf g == fetched t w.wallpaperURL w.wallpaperSHA256) got))
              named)
          ++ lib.optional (builtins.length got != builtins.length named) "count != named entries"
      );
  realCosmic = t: t.config.myconfig.programs.cosmic.enable;
  realChecks = lib.concatMapAttrs
    (n: t: lib.optionalAttrs (realCosmic t) {
      "real-${n}-matches-constants" = safe (failIf (realProblems t));
    })
    real;

  checks = {
    "desktop-like: DP-1 and DP-2 get their own wallpaper, '*' is dropped" =
      safe (failIf (expectProblems (wallpapersOf desktopLike) {
        "DP-1" = fetched desktopLike urlA shaA;
        "DP-2" = fetched desktopLike urlB shaB;
      }));
    "'*' only becomes one 'all' entry" =
      safe (failIf (expectProblems (wallpapersOf starOnly) { all = fetched starOnly urlC shaC; }));
    "video-only '*' uses the fallback wallpaper" =
      safe (failIf (expectProblems (wallpapersOf videoStar) { all = fallbackOf videoStar; }));
    "video-only named entry uses the fallback wallpaper" =
      safe (failIf (expectProblems (wallpapersOf videoNamed) {
        "DP-1" = fallbackOf videoNamed;
        "DP-2" = fetched videoNamed urlB shaB;
      }));
    "desc: target is skipped, others kept" =
      safe (failIf (expectProblems (wallpapersOf descMixed) { "DP-1" = fetched descMixed urlB shaB; }));
    "desc: plus '*' only falls back to the '*' entry as 'all'" =
      safe (failIf (expectProblems (wallpapersOf descOnly) { all = fetched descOnly urlC shaC; }));
    "shell-unsafe target is skipped" =
      safe (failIf (expectProblems (wallpapersOf unsafeName) { "HDMI-A-1" = fetched unsafeName urlB shaB; }));
    "empty wallpapers list gives one 'all' fallback" =
      safe (failIf (expectProblems (wallpapersOf emptyList) { all = fallbackOf emptyList; }));
    "cosmic off: no wallpaper configuration" =
      safe (if wallpapersOf off == null && !(builtins.hasAttr "com.system76.CosmicBackground" (hmCosmic off).configFile) then ok else "FAIL: off twin has wallpaper config");
    "valid twins raise no wallpaper assertion" =
      safe (failIf (lib.concatMap (t: map (a: a.message) (dupAssertion t)) [ desktopLike starOnly descMixed unsafeName emptyList ]));
    "configFile CosmicBackground exists on a cosmic twin" =
      safe (if (hmCosmic desktopLike).configFile ? "com.system76.CosmicBackground" then ok else "FAIL: no CosmicBackground configFile");

    "control: duplicate target trips the single-config assertion" =
      safe (detects "duplicate target" (map (a: a.message) (dupAssertion dupTwin)));
    "control: checker flags duplicate outputs" =
      detects "dups" (shapeProblems [{ output = "DP-1"; source = { __type = "enum"; variant = "Path"; value = [ "/x" ]; }; } { output = "DP-1"; source = { __type = "enum"; variant = "Path"; value = [ "/y" ]; }; }]);
    "control: checker flags unsafe names" =
      detects "unsafe name" (shapeProblems [{ output = "a;b"; source = { __type = "enum"; variant = "Path"; value = [ "/x" ]; }; }]);
    "control: checker flags all mixed with per-output" =
      detects "all mixed" (shapeProblems [
        { output = "all"; source = { __type = "enum"; variant = "Path"; value = [ "/x" ]; }; }
        { output = "DP-1"; source = { __type = "enum"; variant = "Path"; value = [ "/y" ]; }; }
      ]);
    "control: wrong expectation is flagged" =
      detects "wrong path" (expectProblems (wallpapersOf starOnly) { all = "/nix/store/wrong"; });
    "control: missing and unexpected outputs are flagged" =
      detects "missing/unexpected" (expectProblems (wallpapersOf starOnly) { "DP-9" = "/x"; });
  } // realChecks;
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
