let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  mk = lib.mkForce;
  enable = { myconfig.krit.programs.yazi.enable = mk true; };
  show = builtins.toJSON;
  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";

  linuxSys = flake.nixosConfigurations.template-host-minimal.extendModules { modules = [ enable ]; };
  darwinSys = flake.darwinConfigurations.Krits-MacBook-Pro.extendModules { modules = [ enable ]; };
  nasHome = flake.homeConfigurations."krit@Nicol-NAS".extendModules { modules = [ enable ]; };

  hmOf = sys: sys.config.home-manager.users.${sys.config.myconfig.constants.user};
  linux = (hmOf linuxSys).programs.yazi;
  darwin = (hmOf darwinSys).programs.yazi;
  nas = nasHome.config.programs.yazi;

  expectedBefore = [
    [ "open" "reveal" ]
    [ "edit" "reveal" ]
    [ "open" "reveal" ]
    [ "play" "reveal" ]
    [ "extract" "reveal" ]
    [ "edit" "reveal" ]
    [ "edit" "reveal" ]
    [ "edit" "reveal" ]
    "download"
    [ "edit" "reveal" ]
    [ "open" "trash" ]
    [ "open" "reveal" ]
  ];
  expectedFirst = [ "open" "edit" "open" "play" "extract" "edit" "edit" "edit" "download" "edit" "open" "open" ];
  existingOpeners = [ "download" "edit" "extract" "open" "play" "reveal" "trash" ];

  firstOf = u: if builtins.isList u then lib.head u else u;
  rulesOf = y: y.settings.open.rules;
  uses = y: map (r: r.use) (rulesOf y);

  wantedLinux = map (b: if builtins.isList b then b ++ [ "open-with" ] else b) expectedBefore;
  useProblems = withEntry: rules:
    let
      want = if withEntry then wantedLinux else expectedBefore;
      got = map (r: r.use) rules;
    in
    lib.optional (lib.length got != lib.length want) "rule count ${toString (lib.length got)} != ${toString (lib.length want)}"
    ++ lib.concatLists (lib.zipListsWith (g: w: lib.optional (g != w) "${show g} != ${show w}") got want);

  setUse = i: f: rules: lib.imap0 (j: r: if j == i then r // { use = f r.use; } else r) rules;

  openersOf = y: y.settings.opener;
  openerNames = y: lib.sort lib.lessThan (lib.attrNames (openersOf y));
  unresolved = y: lib.unique (lib.filter (n: !(openersOf y ? ${n})) (lib.concatMap (u: if builtins.isList u then u else [ u ]) (uses y)));

  runOf = y: (lib.head (openersOf y).open-with).run;
  ctxNames = v: lib.attrNames (builtins.getContext (builtins.toJSON v));
  linuxRefs = y: lib.filter (n: lib.any (s: lib.hasInfix s n) [ "yazi-open-with" "gtk" "glib" ]) (ctxNames y.settings);
  helperDrvs = lib.filter (n: lib.hasSuffix "-yazi-open-with.drv" n) (ctxNames (openersOf linux));

  keysOf = e: let on = e.on or [ ]; in if builtins.isList on then on else [ on ];
  mgrBindings = km: (km.mgr.prepend_keymap or [ ]) ++ (km.mgr.append_keymap or [ ]) ++ (km.mgr.keymap or [ ]);
  bindsO = km: lib.filter (e: keysOf e != [ ] && builtins.elem (lib.head (keysOf e)) [ "O" "<S-o>" ]) (mgrBindings km);

  openWithShape = y:
    let o = (openersOf y).open-with or [ ]; in
    lib.length o == 1
    && (lib.head o).desc == "Open with..."
    && (lib.head o).block == true
    && (lib.head o).for == "linux"
    && builtins.match "/nix/store/[a-z0-9]{32}-yazi-open-with/bin/yazi-open-with \"\\$1\"" (builtins.unsafeDiscardStringContext (runOf y)) != null;

  checks = {
    check-linux-pick-title-menu = check (linux.settings.pick.open_title == "Menu")
      "pick.open_title is ${show (linux.settings.pick.open_title or null)}";
    check-linux-open-with-opener-shape = check (openWithShape linux)
      "opener.open-with is ${show (builtins.unsafeDiscardStringContext (show (openersOf linux).open-with or null))}";
    check-linux-open-with-run-is-single-helper-closure = check (lib.length helperDrvs == 1)
      "the opener settings reference ${toString (lib.length helperDrvs)} yazi-open-with derivations, expected 1";
    check-linux-existing-openers-kept = check (openerNames linux == lib.sort lib.lessThan (existingOpeners ++ [ "open-with" ]))
      "opener names ${show (openerNames linux)}";
    check-linux-existing-openers-identical-to-darwin = check
      (builtins.removeAttrs (openersOf linux) [ "open-with" ] == openersOf darwin)
      "an existing opener differs between linux and darwin, so the open-with change touched it";
    check-linux-open-rules-end-with-open-with = check (useProblems true (rulesOf linux) == [ ])
      "open.rules use lists: ${show (useProblems true (rulesOf linux))}";
    check-linux-first-opener-unchanged = check (map (r: firstOf r.use) (rulesOf linux) == expectedFirst)
      "first openers ${show (map (r: firstOf r.use) (rulesOf linux))}";
    check-linux-catch-all-rule-last = check ((lib.last (rulesOf linux)).url or null == "*")
      "the last open rule is not the catch-all url \"*\"";
    check-linux-every-used-opener-resolves = check (unresolved linux == [ ])
      "open rules use undefined openers ${show (unresolved linux)}";
    check-linux-keymap-leaves-O-alone = check (mgrBindings linux.keymap != [ ] && bindsO linux.keymap == [ ])
      "mgr keymap binds O (${show (bindsO linux.keymap)}) or is empty (${toString (lib.length (mgrBindings linux.keymap))} entries)";

    check-standalone-home-has-open-with = check
      (openWithShape nas && useProblems true (rulesOf nas) == [ ] && nas.settings.pick.open_title == "Menu")
      "standalone home yazi: shape=${show (openWithShape nas)}, problems=${show (useProblems true (rulesOf nas))}, title=${show (nas.settings.pick.open_title or null)}";

    check-darwin-pick-title-menu = check (darwin.settings.pick.open_title == "Menu")
      "darwin pick.open_title is ${show (darwin.settings.pick.open_title or null)}";
    check-darwin-no-open-with-opener = check (openerNames darwin == existingOpeners)
      "darwin opener names ${show (openerNames darwin)}";
    check-darwin-rules-unchanged = check (useProblems false (rulesOf darwin) == [ ])
      "darwin open.rules use lists: ${show (useProblems false (rulesOf darwin))}";
    check-darwin-settings-do-not-reference-linux-helper = check (linuxRefs darwin == [ ])
      "darwin yazi settings reference ${show (linuxRefs darwin)}";
    check-darwin-every-used-opener-resolves = check (unresolved darwin == [ ])
      "darwin open rules use undefined openers ${show (unresolved darwin)}";
    check-darwin-keymap-leaves-O-alone = check (mgrBindings darwin.keymap != [ ] && bindsO darwin.keymap == [ ])
      "darwin mgr keymap binds O (${show (bindsO darwin.keymap)})";

    check-control-linux-settings-do-reference-helper = check (lib.any (n: lib.hasInfix "yazi-open-with" n) (linuxRefs linux))
      "the linuxRefs probe finds nothing on linux, so the darwin no-reference check is vacuous";
    check-control-lint-flags-open-with-in-middle = check
      (useProblems true (setUse 0 (_: [ "open" "open-with" "reveal" ]) (rulesOf linux)) != [ ])
      "the use-list lint accepts open-with before reveal";
    check-control-lint-flags-missing-open-with = check
      (useProblems true (setUse 11 (u: lib.remove "open-with" u) (rulesOf linux)) != [ ])
      "the use-list lint accepts a rule without open-with";
    check-control-lint-flags-changed-first-opener = check
      (useProblems true (setUse 1 (_: [ "reveal" "edit" "open-with" ]) (rulesOf linux)) != [ ]
        && map firstOf (setUse 1 (_: [ "reveal" "edit" "open-with" ]) (rulesOf linux)) != expectedFirst)
      "the lint and the first-opener literal accept a swapped first opener";
    check-control-lint-flags-download-rule-touched = check
      (useProblems true (setUse 8 (_: [ "download" "open-with" ]) (rulesOf linux)) != [ ])
      "the use-list lint accepts open-with on the vfs download rule";
    check-control-lint-flags-darwin-with-entry = check (useProblems false (rulesOf linux) != [ ])
      "the darwin lint accepts the linux rules, so it cannot detect a leaked entry";
    check-control-unresolved-opener-detected = check
      (unresolved (linux // { settings = linux.settings // { open.rules = setUse 0 (u: u ++ [ "nope" ]) (rulesOf linux); }; }) == [ "nope" ])
      "the unresolved-opener probe does not flag a planted unknown opener";
    check-control-keymap-lint-detects-O = check
      (bindsO { mgr.prepend_keymap = [{ on = [ "O" ]; run = "x"; }]; } != [ ]
        && bindsO { mgr.prepend_keymap = [{ on = [ "O" "x" ]; run = "x"; }]; } != [ ]
        && bindsO { mgr.prepend_keymap = [{ on = "<S-o>"; run = "x"; }]; } != [ ]
        && bindsO { mgr.prepend_keymap = [{ on = [ "o" ]; run = "x"; }]; } == [ ])
      "the keymap lint misses a planted O / O-chord / <S-o> binding or flags lowercase o";
  };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
{
  checks = lib.mapAttrs (_: guard) checks;
  helperDrv = lib.head helperDrvs;
}
