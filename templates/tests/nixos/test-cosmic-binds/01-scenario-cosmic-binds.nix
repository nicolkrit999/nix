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

  cosmicOn = { myconfig.programs.cosmic.enable = mk true; };
  kdeOn = { myconfig.programs.kde.enable = mk true; };
  vicinaeOff = { myconfig.programs.vicinae.enable = mk false; };
  alt = {
    myconfig.constants.terminal.name = mk "kitty";
    myconfig.constants.browser = mk "firefox";
    myconfig.constants.editor = mk "code";
    myconfig.constants.fileManager = mk "yazi";
  };
  extrasOk = {
    myconfig.programs.cosmic.extraBinds = {
      "my-args" = {
        key = "Super+X";
        command = "foo --bar \"baz qux\" 'q'";
        name = "Mine";
      };
      "my-shifted" = {
        key = "Shift+Super+Y";
        command = "bar";
        name = "Shifted";
      };
    };
  };
  extrasClashBuiltin = {
    myconfig.programs.cosmic.extraBinds."clash" = { key = "super+b"; command = "other"; name = "Clash"; };
  };
  extrasClashEachOther = {
    myconfig.programs.cosmic.extraBinds = {
      "first" = { key = "Super+Shift+Z"; command = "one"; name = "One"; };
      "second" = { key = "Shift+Super+z"; command = "two"; name = "Two"; };
    };
  };

  twin = modules: fx.mkNixos modules;
  base = twin [ cosmicOn kdeOn ];
  altT = twin [ cosmicOn kdeOn alt ];
  noVic = twin [ cosmicOn kdeOn vicinaeOff ];
  extrasT = twin [ cosmicOn extrasOk ];
  clashBuiltinT = twin [ cosmicOn extrasClashBuiltin ];
  clashEachT = twin [ cosmicOn extrasClashEachOther ];
  off = twin [{ myconfig.programs.cosmic.enable = mk false; } extrasOk];
  offStylix = twin [{ myconfig.programs.cosmic.enable = mk false; stylix.enable = mk true; }];
  onStylix = twin [ cosmicOn { stylix.enable = mk true; } ];
  onNoStylix = twin [ cosmicOn { myconfig.stylix.enable = mk false; } ];

  cosmicOf = t: (fx.hmOf t).wayland.desktopManager.cosmic;
  everyShortcutOf = t: (cosmicOf t).shortcuts;
  isDisable = s: (s.action.variant or "") == "Disable";
  allShortcutsOf = t: lib.filter (s: !(isDisable s)) (everyShortcutOf t);
  disablesOf = t: lib.filter isDisable (everyShortcutOf t);
  shadowDefault = [ "super+escape" "shift+super+escape" "super+q" "super+f11" "super+t" ];
  disableShapeOk = s: (s.description or null) == null && removeAttrs s [ "description" ] == { key = s.key; action = { __type = "enum"; variant = "Disable"; }; };
  disableProblems = sc: active:
    let ks = map (s: normKey s.key) sc; in
    map (s: "bad Disable shape for ${s.key}") (lib.filter (s: !(disableShapeOk s)) sc)
    ++ map (k: "missing Disable ${k}") (lib.filter (k: !(builtins.elem k ks)) shadowDefault)
    ++ map (k: "unexpected Disable ${k}") (lib.filter (k: !(builtins.elem k shadowDefault)) ks)
    ++ map (k: "duplicate Disable ${k}") (dups ks)
    ++ map (k: "Disable ${k} equals an active bind") (lib.filter (k: builtins.elem k (map (s: normKey s.key) active)) ks);
  isSpawn = s: (s.action.variant or "") == "Spawn";
  shotKeys = [ "ctrl+super+3" "ctrl+super+4" ];
  isShot = s: builtins.elem (normKey s.key) shotKeys;
  shortcutsOf = t: lib.filter (s: isSpawn s && !(isShot s)) (allShortcutsOf t);
  shotsOf = t: lib.filter (s: isSpawn s && isShot s) (allShortcutsOf t);
  shotProblems = t:
    let
      sh = shotsOf t;
      by = k: lib.filter (s: normKey s.key == k) sh;
      full = by "ctrl+super+3";
      sel = by "ctrl+super+4";
      dir = (constsOf t).screenshots;
      fullCmd = cmdOf (lib.head full);
      selCmd = cmdOf (lib.head sel);
      script = builtins.readFile fullCmd;
    in
    if builtins.length full != 1 || builtins.length sel != 1 || builtins.length sh != 2 then [ "expected exactly one bind each on Super+Ctrl+3 and Super+Ctrl+4" ]
    else
      map (s: "bad Spawn shape for ${s.key}") (lib.filter (s: !(spawnShapeOk s)) sh)
      ++ lib.optional (lib.hasInfix " " fullCmd) "full-screen command is not a bare script path: ${fullCmd}"
      ++ lib.optional (!(lib.hasInfix "dir=\"${dir}\"" script)) "script does not set dir to constants.screenshots"
      ++ lib.optional (!(lib.hasInfix "mkdir -p \"$dir\"" script)) "script lacks mkdir -p \"$dir\""
      ++ lib.optional (!(lib.hasInfix "/bin/grim \"$dir/Screenshot_$(date +%F_%H-%M-%S).png\"" script)) "script lacks the grim call into $dir"
      ++ lib.optional (!(lib.hasSuffix "/bin/cosmic-screenshot" selCmd)) "select bind is not the cosmic-screenshot binary: ${selCmd}"
      ++ lib.optional (lib.hasInfix " " selCmd) "select bind carries flags: ${selCmd}";
  isSystem = s: (s.action.variant or "") == "System";
  mkDisable = key: { inherit key; action = { __type = "enum"; variant = "Disable"; }; };
  windowOf = t: lib.filter (s: !(isSpawn s) && !(isSystem s)) (allShortcutsOf t);
  systemOf = t: lib.filter isSystem (allShortcutsOf t);
  constsOf = t: t.config.myconfig.constants;

  dups = l: lib.unique (lib.filter (x: lib.count (y: y == x) l > 1) l);
  canon = mods: key: lib.concatStringsSep "+" (lib.sort (a: b: a < b) (map lib.toLower mods) ++ [ (lib.toLower key) ]);
  normKey = s:
    let p = lib.splitString "+" s; in
    canon (lib.init p) (lib.last p);
  kdeToCosmicKey = s:
    let
      p = lib.splitString "+" s;
      mods = map (m: if lib.toLower m == "meta" then "super" else m) (lib.init p);
      k = lib.last p;
    in
    canon mods (if k == "." then "period" else k);
  kdeToCosmicKeyNoPeriod = s:
    let p = lib.splitString "+" s; in
    canon (map (m: if lib.toLower m == "meta" then "super" else m) (lib.init p)) (lib.last p);

  cmdOf = s: lib.head s.action.value;
  spawnShapeOk = s:
    s.action.__type or "" == "enum"
    && s.action.variant or "" == "Spawn"
    && builtins.isList s.action.value
    && builtins.length s.action.value == 1
    && builtins.isString (lib.head s.action.value)
    && lib.head s.action.value != "";
  windowExpected = {
    "shift+super+c" = "Close";
    "shift+super+m" = "Minimize";
    "shift+super+f" = "Fullscreen";
    "super+m" = "Fullscreen";
    "alt+super+a" = "Maximize";
  };
  systemExpected = {
    "super+delete" = "LockScreen";
    "shift+super+delete" = "LogOut";
  };
  systemShapeOk = s: s.action == {
    __type = "enum";
    variant = "System";
    value = [{ __type = "enum"; variant = systemExpected.${normKey s.key} or "?"; }];
  };
  systemProblems = sc:
    let
      want = systemExpected;
    in
    map (k: "missing system ${k}") (lib.filter (k: !(lib.any (s: normKey s.key == k) sc)) (builtins.attrNames want))
    ++ map (s: "unexpected system key ${s.key}") (lib.filter (s: !(want ? ${normKey s.key})) sc)
    ++ map (s: "bad system action shape for ${s.key}") (lib.filter (s: !(systemShapeOk s)) sc)
    ++ map (s: "system bind without description ${s.key}") (lib.filter (s: !(windowDescOk s)) sc);
  windowShapeOk = s: s.action == { __type = "enum"; variant = windowExpected.${normKey s.key} or "?"; };
  windowDescOk = s: s.description.__type or "" == "optional" && builtins.isString (s.description.value or null) && s.description.value != "";
  windowProblems = sc:
    let
      got = lib.listToAttrs (map (s: { name = normKey s.key; value = s.action.variant or "?"; }) sc);
      want = windowExpected;
    in
    map (k: "missing window ${k}") (lib.filter (k: !(got ? ${k})) (builtins.attrNames want))
    ++ map (k: "unexpected non-Spawn ${k}") (lib.filter (k: !(want ? ${k})) (builtins.attrNames got))
    ++ map (k: "${k}: ${got.${k}} != ${want.${k}}") (lib.filter (k: got ? ${k} && want ? ${k} && got.${k} != want.${k}) (builtins.attrNames want))
    ++ map (s: "bad window action shape for ${s.key}") (lib.filter (s: !(windowShapeOk s)) sc)
    ++ map (s: "window bind without description ${s.key}") (lib.filter (s: !(windowDescOk s)) sc);
  cmdMap = sc: lib.listToAttrs (map (s: { name = normKey s.key; value = cmdOf s; }) sc);

  uniqueProblems = sc:
    map (k: "duplicate key ${k}") (dups (map (s: normKey s.key) sc));

  setProblems = sc: pred:
    let
      got = cmdMap sc;
      missing = lib.filter (k: !(got ? ${k})) (builtins.attrNames pred);
      unexpected = lib.filter (k: !(pred ? ${k})) (builtins.attrNames got);
      wrong = lib.filter (k: got ? ${k} && pred ? ${k} && got.${k} != pred.${k}) (builtins.attrNames pred);
    in
    map (k: "missing ${k}") missing
    ++ map (k: "unexpected ${k}") unexpected
    ++ map (k: "${k}: ${got.${k}} != ${pred.${k}}") wrong
    ++ map (s: "bad Spawn shape for ${s.key}") (lib.filter (s: !(spawnShapeOk s)) sc);

  wrapWith = termApps: term: app: if builtins.elem app termApps then "${term} -e ${app}" else app;
  predicted = { c, vicinae ? true, extras ? { } }:
    let wrap = wrapWith c.terminalApps c.terminal.name; in
    {
      "super+return" = c.terminal.name;
      "super+b" = c.browser;
      "super+c" = wrap c.editor;
      "super+f" = wrap c.fileManager;
    }
    // lib.optionalAttrs vicinae {
      "super+a" = "vicinae toggle";
      "super+v" = "vicinae vicinae://launch/clipboard/history";
      "super+period" = "vicinae vicinae://launch/core/search-emojis";
    }
    // lib.mapAttrs' (_: v: { name = normKey v.key; value = v.command; }) extras;

  predOf = t: args: predicted ({ c = constsOf t; } // args);
  extrasDecl = extrasOk.myconfig.programs.cosmic.extraBinds;

  sharedKde = [ "launch-terminal" "launch-browser" "launch-editor" "launch-filemanager" "vicinae-toggle" "vicinae-clipboard" "vicinae-emoji" ];
  kdeMapOf = t:
    let cmds = (fx.hmOf t).programs.plasma.hotkeys.commands; in
    lib.listToAttrs (map
      (n: { name = kdeToCosmicKey cmds.${n}.key; value = cmds.${n}.command; })
      (lib.filter (n: cmds ? ${n}) sharedKde));
  kdeProblems = t: setProblems (shortcutsOf t) (kdeMapOf t);

  finalOf = t: (cosmicOf t).configFile."com.system76.CosmicSettings.Shortcuts".entries.custom.value;
  actLabel = a: if a.variant == "Spawn" then lib.head a.value else a.variant;
  finalPairs = entries: lib.sort (a: b: a < b) (map
    (e: "${canon (map (m: m.variant) e.key.modifiers) e.key.key} => ${actLabel e.value}")
    entries);
  shortcutPairs = sc: lib.sort (a: b: a < b) (map (s: "${normKey s.key} => ${actLabel s.action}") sc);
  finalProblems = t:
    let f = finalPairs (finalOf t); s = shortcutPairs (everyShortcutOf t); in
    lib.optional (f != s) "configFile entries [${lib.concatStringsSep ", " f}] != shortcuts [${lib.concatStringsSep ", " s}]";

  tkRel = "share/cosmic/com.system76.CosmicTk/v1";
  tkPackage = cfg: lib.findFirst (p: lib.getName p == "cosmic-tk-fonts") null cfg.environment.systemPackages;
  fontFileProblems = family: file: text:
    lib.optional (!(lib.hasInfix "family: \"${family}\"" text)) "${file} lacks family \"${family}\"";
  tkProblems = cfg:
    let p = tkPackage cfg; in
    if p == null then [ "cosmic-tk-fonts package missing from systemPackages" ]
    else
      let
        read = f: builtins.readFile "${p}/${tkRel}/${f}";
        sans = cfg.stylix.fonts.sansSerif.name;
        mono = cfg.stylix.fonts.monospace.name;
      in
      lib.optional (sans == mono) "sansSerif and monospace names are equal, the check cannot tell the files apart"
      ++ fontFileProblems sans "interface_font" (read "interface_font")
      ++ fontFileProblems mono "monospace_font" (read "monospace_font");

  sessionVars = t: (fx.hmOf t).home.sessionVariables;

  baseSc = shortcutsOf base;
  baseAll = allShortcutsOf base;
  baseShots = shotsOf base;
  basePred = predOf base { };
  dropOne = sc: lib.tail sc;

  checks = {
    "binds: keys unique after normalisation across Spawn and window binds (defaults)" = failIf (uniqueProblems baseAll);
    "binds: command set equals the set derived from constants (defaults)" = failIf (setProblems baseSc basePred);
    "binds: every action is one non-empty Spawn string (defaults)" =
      failIf (map (s: "bad Spawn shape for ${s.key}") (lib.filter (s: !(spawnShapeOk s)) baseSc));
    "binds: exactly the 4 launcher binds plus 3 vicinae binds as Spawn" =
      if builtins.length baseSc == 7 then ok else "FAIL: ${toString (builtins.length baseSc)} Spawn shortcuts";
    "binds: 16 active shortcuts in total (7 Spawn + 2 screenshot + 5 window actions + 2 System actions)" =
      if builtins.length baseAll == 16 then ok else "FAIL: ${toString (builtins.length baseAll)} active shortcuts";
    "binds: 21 shortcut entries including the 5 Disable shadows" =
      if builtins.length (everyShortcutOf base) == 21 && builtins.length (disablesOf base) == 5 then ok else "FAIL: ${toString (builtins.length (everyShortcutOf base))} entries, ${toString (builtins.length (disablesOf base))} Disable";
    "disable: exactly the five default shadows with the bare Disable shape, none equal to an active bind (defaults)" =
      failIf (disableProblems (disablesOf base) baseAll);
    "disable: identical with vicinae off, alt constants and extras" =
      failIf (lib.concatMap (t: disableProblems (disablesOf t) (allShortcutsOf t)) [ noVic altT extrasT ]);
    "disable: Super+M is a Fullscreen bind and no Disable, Super+Alt+A is Maximize" =
      let
        at = k: lib.filter (s: normKey s.key == k) (everyShortcutOf base);
      in
      failIf (
        lib.optional (map (s: s.action.variant) (at "super+m") != [ "Fullscreen" ]) "Super+M is not exactly one Fullscreen"
        ++ lib.optional (map (s: s.action.variant) (at "alt+super+a") != [ "Maximize" ]) "Super+Alt+A is not exactly one Maximize"
      );
    "disable: control, a Disable on an active key is flagged" =
      detects "Disable on active key" (disableProblems (disablesOf base ++ [ (mkDisable "Super+B") ]) baseAll);
    "disable: control, a wrong variant is flagged" =
      detects "wrong variant" (disableProblems (map (s: s // { action = { __type = "enum"; variant = "Close"; }; }) (disablesOf base)) baseAll);
    "disable: control, an extra unknown Disable is flagged" =
      detects "unknown Disable" (disableProblems (disablesOf base ++ [ (mkDisable "Super+Z") ]) baseAll);
    "disable: control, a missing Disable is flagged" =
      detects "missing Disable" (disableProblems (lib.tail (disablesOf base)) baseAll);
    "disable: control, a description on a Disable is flagged" =
      detects "described Disable" (disableProblems (map (s: s // { description = { __type = "optional"; value = "x"; }; }) (disablesOf base)) baseAll);

    "screenshot: Super+Ctrl+3 is a grim script writing into constants.screenshots, Super+Ctrl+4 is bare cosmic-screenshot (defaults)" =
      failIf (shotProblems base);
    "screenshot: same with alt constants, vicinae off and extras" =
      failIf (lib.concatMap shotProblems [ altT noVic extrasT ]);
    "screenshot: Print is not rebound" =
      failIf (map (s: "Print rebound: ${s.key}") (lib.filter (s: normKey s.key == "print") baseAll));
    "screenshot: control, a wrong directory in the script check is flagged" =
      detects "dir mismatch" (shotProblems (base // { config = base.config // { myconfig = base.config.myconfig // { constants = base.config.myconfig.constants // { screenshots = "/elsewhere"; }; }; }; }));
    "screenshot: control, a flagged Spawn shape on a screenshot bind" =
      detects "bad shape" (map (s: "bad Spawn shape for ${s.key}") (lib.filter (s: !(spawnShapeOk s)) [ ((lib.head baseShots) // { action = { __type = "enum"; variant = "Spawn"; value = [ ]; }; }) ]));

    "window: exactly Fullscreen on Super+M and Super+Shift+F, Maximize on Super+Alt+A, Close and Minimize on Super+Shift+C/M with the exact enum shape (defaults)" =
      failIf (windowProblems (windowOf base));
    "window: present and identical with vicinae off, alt constants and extras" =
      failIf (lib.concatMap (t: windowProblems (windowOf t)) [ noVic altT extrasT ]);
    "window: no key of a window bind is shared with a Spawn bind" =
      let sp = map (s: normKey s.key) baseSc; in
      failIf (map (s: "window key ${s.key} also Spawn") (lib.filter (s: builtins.elem (normKey s.key) (sp ++ shotKeys)) (windowOf base)));
    "window: control, a missing window bind is flagged" =
      detects "missing window bind" (windowProblems (lib.tail (windowOf base)));
    "window: control, an unexpected non-Spawn bind is flagged" =
      detects "unexpected non-Spawn" (windowProblems (windowOf base ++ [{ key = "Super+Z"; description = { __type = "optional"; value = "x"; }; action = { __type = "enum"; variant = "Terminate"; }; }]));
    "window: control, a wrong variant on an expected key is flagged" =
      detects "wrong variant" (windowProblems (map (s: s // { action = { __type = "enum"; variant = "Maximize"; }; }) (windowOf base)));
    "window: control, an extra field on the action is flagged" =
      detects "action shape" (windowProblems (map (s: s // { action = s.action // { value = [ ]; }; }) (windowOf base)));
    "window: control, a missing description is flagged" =
      detects "no description" (windowProblems (map (s: removeAttrs s [ "description" ]) (windowOf base)));
    "window: a window key declared as extraBind collides across Spawn and window binds" =
      let p = uniqueProblems (allShortcutsOf (twin [ cosmicOn { myconfig.programs.cosmic.extraBinds."x" = { key = "Shift+Super+c"; command = "x"; name = "X"; }; } ])); in
      if p == [ "duplicate key shift+super+c" ] then ok else "FAIL: expected exactly the shift+super+c duplicate, got [${lib.concatStringsSep "; " p}]";

    "system: exactly LockScreen on Super+Delete and LogOut on Super+Shift+Delete with the nested System enum shape (defaults)" =
      failIf (systemProblems (systemOf base));
    "system: present and identical with vicinae off, alt constants and extras" =
      failIf (lib.concatMap (t: systemProblems (systemOf t)) [ noVic altT extrasT ]);
    "system: keys are unique across all binds including the new ones" =
      failIf (uniqueProblems baseAll
        ++ map (k: "system key ${k} missing from the generated binds") (lib.filter (k: !(builtins.elem k (map (s: normKey s.key) baseAll))) (builtins.attrNames systemExpected)));
    "system: control, a missing system bind is flagged" =
      detects "missing system bind" (systemProblems (lib.tail (systemOf base)));
    "system: control, a wrong System variant is flagged" =
      detects "wrong system variant" (systemProblems (map (s: s // { action = s.action // { value = [{ __type = "enum"; variant = "PowerOff"; }]; }; }) (systemOf base)));
    "system: control, a flat (non-nested) System action is flagged" =
      detects "flat system shape" (systemProblems (map (s: s // { action = { __type = "enum"; variant = "LockScreen"; }; }) (systemOf base)));
    "system: control, an unexpected system key is flagged" =
      detects "unexpected system key" (systemProblems (systemOf base ++ [ ((lib.head (systemOf base)) // { key = "Super+Q"; }) ]));
    "system: control, a missing description is flagged" =
      detects "no description" (systemProblems (map (s: removeAttrs s [ "description" ]) (systemOf base)));

    "constants: terminal/browser/editor/fileManager changes reach the binds" =
      failIf (uniqueProblems (shortcutsOf altT) ++ setProblems (shortcutsOf altT) (predOf altT { }));
    "constants: the fixture variation really changed the constants" =
      let c = constsOf altT; in
      if c.terminal.name == "kitty" && c.browser == "firefox" && c.editor == "code" && c.fileManager == "yazi" then ok
      else "FAIL: constants variation did not apply";
    "constants: terminalApps membership decides the terminal wrapper (editor and fileManager flip)" =
      let
        b = cmdMap baseSc;
        a = cmdMap (shortcutsOf altT);
        bc = constsOf base;
        ac = constsOf altT;
      in
      failIf (
        lib.optional (!(builtins.elem bc.editor bc.terminalApps && !(builtins.elem bc.fileManager bc.terminalApps))) "base fixture is not editor-in-apps / fileManager-not-in-apps"
        ++ lib.optional (!(builtins.elem ac.fileManager ac.terminalApps && !(builtins.elem ac.editor ac.terminalApps))) "alt fixture is not fileManager-in-apps / editor-not-in-apps"
        ++ lib.optional (b."super+c" != "${bc.terminal.name} -e ${bc.editor}") "base editor not wrapped: ${b."super+c"}"
        ++ lib.optional (b."super+f" != bc.fileManager) "base fileManager wrapped: ${b."super+f"}"
        ++ lib.optional (a."super+c" != ac.editor) "alt editor wrapped: ${a."super+c"}"
        ++ lib.optional (a."super+f" != "${ac.terminal.name} -e ${ac.fileManager}") "alt fileManager not wrapped: ${a."super+f"}"
      );
    "constants: control, the two constant sets produce different command sets" =
      if lib.sort (a: b: a < b) (map cmdOf baseSc) != lib.sort (a: b: a < b) (map cmdOf (shortcutsOf altT)) then ok
      else "FAIL: base and alt command sets are identical, the variation test is vacuous";
    "constants: control, defaults prediction does not match the alt binds" =
      detects "alt binds vs default prediction" (setProblems (shortcutsOf altT) basePred);

    "vicinae: enabled gives exactly the three vicinae binds" =
      let
        got = cmdMap baseSc;
        v = [ "super+a" "super+v" "super+period" ];
      in
      failIf (map (k: "missing ${k}") (lib.filter (k: !(got ? ${k})) v));
    "vicinae: disabled drops them and keeps the launcher binds" =
      let sc = shortcutsOf noVic; in
      failIf (uniqueProblems sc ++ setProblems sc (predOf noVic { vicinae = false; }));
    "vicinae: disabled leaves no vicinae command anywhere" =
      failIf (map (s: "vicinae command ${cmdOf s}") (lib.filter (s: lib.hasPrefix "vicinae" (cmdOf s)) (shortcutsOf noVic)));
    "vicinae: control, the enabled prediction is flagged against the disabled binds" =
      detects "vicinae binds predicted but absent" (setProblems (shortcutsOf noVic) (predOf noVic { vicinae = true; }));
    "vicinae: control, the disabled prediction is flagged against the enabled binds" =
      detects "vicinae binds present but not predicted" (setProblems baseSc (predOf base { vicinae = false; }));

    "kde parity: shared subset equals the KDE binds (Meta to Super, dot to period), defaults" = failIf (kdeProblems base);
    "kde parity: shared subset equals the KDE binds, alt constants" = failIf (kdeProblems altT);
    "kde parity: shared subset equals the KDE binds, vicinae disabled" = failIf (kdeProblems noVic);
    "kde parity: the KDE side really holds all seven shared binds (defaults)" =
      if builtins.length (builtins.attrNames (kdeMapOf base)) == 7 then ok else "FAIL: KDE side has ${toString (builtins.length (builtins.attrNames (kdeMapOf base)))} shared binds";
    "kde parity: control, a changed KDE command is flagged" =
      let m = kdeMapOf base; in
      detects "tampered KDE command" (setProblems baseSc (m // { "super+b" = "tampered"; }));
    "kde parity: control, a KDE bind missing on the COSMIC side is flagged" =
      detects "missing COSMIC bind" (setProblems (dropOne baseSc) (kdeMapOf base));
    "kde parity: control, an extra KDE-only key is flagged" =
      detects "extra bind" (setProblems baseSc (kdeMapOf base // { "super+ctrl+0" = "spectacle"; }));
    "kde parity: control, skipping the dot to period mapping would not match" =
      let
        cmds = (fx.hmOf base).programs.plasma.hotkeys.commands;
        unmapped = lib.listToAttrs (map (n: { name = kdeToCosmicKeyNoPeriod cmds.${n}.key; value = cmds.${n}.command; }) sharedKde);
      in
      detects "unmapped dot" (setProblems baseSc unmapped);

    "extraBinds: included in shortcuts next to the built-ins, clean set" =
      let sc = shortcutsOf extrasT; in
      failIf (uniqueProblems sc ++ setProblems sc (predOf extrasT { extras = extrasDecl; }));
    "extraBinds: a command with arguments and quotes survives as one Spawn string" =
      let
        hit = lib.filter (s: normKey s.key == "super+x") (shortcutsOf extrasT);
      in
      if builtins.length hit == 1 && cmdOf (lib.head hit) == extrasDecl."my-args".command && spawnShapeOk (lib.head hit) then ok
      else "FAIL: argument command mangled or not a single Spawn string";
    "extraBinds: modifier order in the declared key does not matter (Shift+Super+Y is present)" =
      let got = cmdMap (shortcutsOf extrasT); in
      if got."shift+super+y" or null == "bar" then ok else "FAIL: Shift+Super+Y bind missing";
    "extraBinds: control, omitting the extras from the prediction is flagged" =
      detects "extras unpredicted" (setProblems (shortcutsOf extrasT) (predOf extrasT { }));
    "extraBinds: a key colliding with a built-in key is detected by the uniqueness check" =
      let p = uniqueProblems (shortcutsOf clashBuiltinT); in
      if p == [ "duplicate key super+b" ] then ok else "FAIL: expected exactly the super+b duplicate, got [${lib.concatStringsSep "; " p}]";
    "extraBinds: two extras with the same key (different modifier order) are detected" =
      let p = uniqueProblems (shortcutsOf clashEachT); in
      if p == [ "duplicate key shift+super+z" ] then ok else "FAIL: expected exactly the shift+super+z duplicate, got [${lib.concatStringsSep "; " p}]";
    "extraBinds: control, the clean defaults and clean extras report no duplicate" =
      if uniqueProblems baseSc == [ ] && uniqueProblems (shortcutsOf extrasT) == [ ] then ok else "FAIL: uniqueness check flags clean binds";
    "extraBinds: control, a synthetic duplicated list is detected" =
      detects "duplicated entry" (uniqueProblems (baseSc ++ [ (lib.head baseSc) ]));
    "extraBinds: control, a case-variant synthetic duplicate is detected" =
      detects "case variant" (uniqueProblems (baseSc ++ [ ((lib.head baseSc) // { key = lib.toLower (lib.head baseSc).key; }) ]));
    "extraBinds: control, a synthetic list missing a built-in is flagged by the set check" =
      detects "missing bind" (setProblems (dropOne baseSc) basePred);
    "extraBinds: control, a synthetic unpredicted extra is flagged by the set check" =
      detects "extra bind" (setProblems (baseSc ++ [ ((lib.head baseSc) // { key = "Super+Q"; }) ]) basePred);
    "extraBinds: control, a non-Spawn action is flagged by the shape check" =
      detects "bad shape" (setProblems [ ((lib.head baseSc) // { action = { __type = "enum"; variant = "Disable"; value = [ ]; }; }) ] { });

    "final form: configFile entries equal the shortcuts (defaults)" = failIf (finalProblems base);
    "final form: configFile entries equal the shortcuts (extras incl. arguments)" = failIf (finalProblems extrasT);
    "final form: control, a tampered entry list is flagged" =
      let e = finalOf base; in
      detects "tampered final entry"
        (lib.optional (finalPairs (lib.tail e) != shortcutPairs (everyShortcutOf base)) "differs");

    "unchanged: cosmic-tk-fonts present with cosmic and stylix on, carrying the stylix fonts" = failIf (tkProblems onStylix.config);
    "unchanged: cosmic-tk-fonts absent with cosmic on and stylix off" =
      if !onNoStylix.config.stylix.enable && tkPackage onNoStylix.config == null then ok else "FAIL: cosmic-tk-fonts present with stylix off";
    "unchanged: cosmic-tk-fonts absent with cosmic off and stylix on" =
      if tkPackage offStylix.config == null then ok else "FAIL: cosmic-tk-fonts present with cosmic off";
    "unchanged: control, a missing package is detected by the font check" = detects "no package" (tkProblems offStylix.config);
    "unchanged: XDG_SCREENSHOTS_DIR equals constants.screenshots with cosmic on" =
      let v = sessionVars base; in
      if v.XDG_SCREENSHOTS_DIR or null == (constsOf base).screenshots then ok
      else "FAIL: XDG_SCREENSHOTS_DIR is ${builtins.toJSON (v.XDG_SCREENSHOTS_DIR or null)}";
    "unchanged: COSMIC_DATA_CONTROL_ENABLED is set with cosmic on" =
      if (sessionVars base).COSMIC_DATA_CONTROL_ENABLED or null == 1 then ok else "FAIL: COSMIC_DATA_CONTROL_ENABLED not 1";
    "unchanged: control, cosmic off sets neither session variable" =
      let v = sessionVars off; in
      if !(v ? XDG_SCREENSHOTS_DIR) && !(v ? COSMIC_DATA_CONTROL_ENABLED) then ok else "FAIL: cosmic session variables leak with cosmic off";
    "idle: screen_off_time is hypridle screenOffTimeout in ms, both suspend timers are None" =
      let
        i = (cosmicOf base).idle;
        secs = base.config.myconfig.services.hypridle.screenOffTimeout;
      in
      if i.screen_off_time == { __type = "optional"; value = secs * 1000; }
        && i.suspend_on_ac_time == { __type = "optional"; value = null; }
        && i.suspend_on_battery_time == { __type = "optional"; value = null; }
      then ok else "FAIL: idle is ${builtins.toJSON i}";
    "idle: control, cosmic off sets no idle config" =
      if (cosmicOf off).idle == null then ok else "FAIL: idle set with cosmic off";
    "unchanged: control, cosmic off generates no shortcuts even with extraBinds declared" =
      if (everyShortcutOf off == null || everyShortcutOf off == [ ]) && (cosmicOf off).enable == false then ok else "FAIL: shortcuts generated with cosmic off";
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
