let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  src = /. + builtins.unsafeDiscardStringContext flake.outPath;
  denix = flake.inputs.denix;
  lib = flake.inputs.nixpkgs.lib;

  here = src + "/templates/tests/nixos/test-spec-ryoku/fixture";
  genericFile = src + "/modules/nixos/specializations/ryoku.nix";
  layerFile = src + "/users/krit/nixos/specializations/ryoku.nix";
  portalFile = src + "/modules/nixos/toplevel/xdg-portal-config.nix";
  bindsFile = src + "/modules/nixos/specializations/ryoku-binds.nix";
  libDirStr = builtins.unsafeDiscardStringContext flake.outPath + "/modules/nixos/programs/de-wm/binds-lib";
  genericText = builtins.readFile genericFile;
  bindsText = builtins.readFile bindsFile;
  layerText = builtins.readFile layerFile;
  probes = import (here + "/probes.nix") { inherit lib; };
  portalFileStr = builtins.unsafeDiscardStringContext flake.outPath + "/modules/nixos/toplevel/xdg-portal-config.nix";
  portalConfig = import portalFile { inherit lib; };

  repl = from: to: text:
    let n = builtins.length (lib.splitString from text) - 1; in
    assert lib.assertMsg (n == 1) "mutation anchor '${from}' matches ${toString n} times";
    builtins.replaceStrings [ from ] [ to ] text;
  # A derivation (built by the readFile below) instead of builtins.toFile: under lazy trees a
  # toFile path is virtual, so lib.fileset (denix paths) reports "path does not exist" in CI.
  pkgs = flake.inputs.nixpkgs.legacyPackages.${builtins.currentSystem};
  load = text:
    let f = pkgs.writeText "ryoku-mutant.nix" (builtins.replaceStrings [ "../toplevel/xdg-portal-config.nix" "../programs/de-wm/binds-lib" ] [ portalFileStr libDirStr ] text);
    in builtins.seq (builtins.readFile f) (/. + builtins.unsafeDiscardStringContext "${f}");
  mutate = from: to: text: load (repl from to text);
  mutateBoth = from: to: text:
    let n = builtins.length (lib.splitString from text) - 1; in
    assert lib.assertMsg (n == 2) "mutation anchor '${from}' matches ${toString n} times, expected 2 (settings and emblem unit)";
    load (builtins.replaceStrings [ from ] [ to ] text);

  mk = { name, user, host, generic ? genericFile, bindsModule ? bindsFile, extra ? [ ] }:
    (denix.lib.configurations {
      moduleSystem = "nixos";
      homeManagerUser = user;
      extensions = with denix.lib.extensions; [
        args
        (base.withConfig {
          args.enable = true;
          rices.enable = false;
        })
        (import (here + "/home-user-follows-constants.nix") { inherit denix; moduleSystem = "nixos"; })
      ];
      specialArgs = {
        inherit (flake) inputs;
        moduleSystem = "nixos";
      };
      paths = [
        (here + "/${host}")
        (here + "/nixos-extra.nix")
        (here + "/option-sinks.nix")
        (here + "/nixos-sessions.nix")
        (src + "/modules/nixos/toplevel/home-manager.nix")
        (src + "/modules/nixos/config/constants-nixos.nix")
        (src + "/modules/common/config/constants.nix")
        (src + "/modules/nixos/services/impermanence.nix")
        (src + "/modules/nixos/toplevel/stylix-nixos.nix")
        (here + "/bind-option-sinks.nix")
        bindsModule
        generic
      ] ++ extra;
      exclude = [ ];
    }).${name};

  layer = [ layerFile (here + "/krit-option-sinks.nix") ];
  bob = mk { name = "ryoku-bob"; user = "bob"; host = "host-bob.nix"; extra = layer; };
  alice = mk { name = "ryoku-alice"; user = "alice"; host = "host-alice.nix"; };
  arm = mk { name = "ryoku-arm"; user = "bob"; host = "host-aarch64.nix"; };
  noPortalForce = mk {
    name = "ryoku-bob";
    user = "bob";
    host = "host-bob.nix";
    generic = mutate "xdg.portal.config = lib.mkForce portalConfig;" "" genericText;
  };
  noX86Assertion = mk {
    name = "ryoku-arm";
    user = "bob";
    host = "host-aarch64.nix";
    generic = mutate "assertion = isX86;" "assertion = true;" genericText;
  };
  noMangoFilter = mk {
    name = "ryoku-bob";
    user = "bob";
    host = "host-bob.nix";
    generic = mutate "lib.filter (p: !(lib.elem \"ryoku-mango\" p.providedSessions)) dm.sessionPackages" "dm.sessionPackages" genericText;
  };
  noVicinaeOff = mk {
    name = "ryoku-bob";
    user = "bob";
    host = "host-bob.nix";
    generic = mutate "    [ \"programs\" \"vicinae\" ]\n" "" genericText;
  };

  spec = h: h.config.specialisation.ryoku.configuration;
  baseUser = h: h.config.myconfig.constants.user;
  ryokuUser = h: (spec h).myconfig.constants.user;
  usersOf = c: c.users.users;
  hmUsers = c: lib.attrNames c.home-manager.users;
  rangesOf = u: kind: map (r: { start = r.startUid or r.startGid; inherit (r) count; }) (u.${kind} or [ ]);
  overlaps = a: b: lib.any (x: lib.any (y: x.start < y.start + y.count && y.start < x.start + x.count) b) a;
  optOf = c: p: lib.attrByPath ([ "myconfig" ] ++ p ++ [ "enable" ]) null c;
  showPath = lib.concatStringsSep ".";

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";
  failed = r: lib.hasPrefix "FAIL" r;

  offPaths =
    map (n: [ "programs" n ]) [ "cosmic" "gnome" "hyprland" "kde" "mango" "niri" "caelestia" "noctalia" "skwdWall" "vicinae" "walker" "swayosd" "waybar-hyprland" "waybar-mango" "waybar-niri" "fastfetch" "starship" ]
    ++ map (n: [ "services" n ]) [ "auto-cpufreq" "coffee" "hypridle" "sddm-astronaut" "sddm-pixie" "swaync" "tlp" ]
    ++ [ [ "qt" ] [ "bluetooth" ] ];
  forcedOff = paths: h:
    let
      baseNotOn = lib.filter (p: optOf h.config p != true) paths;
      stillOn = lib.filter (p: optOf (spec h) p != false) paths;
    in
    if baseNotOn != [ ] then "FAIL: control: base does not have these on: ${toString (map showPath baseNotOn)}"
    else if stillOn != [ ] then "FAIL: not false in the spec: ${toString (map showPath stillOn)}"
    else "ok";

  borgPaths = [
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
  ];
  reenablePaths = [
    [ "krit" "home" "base" ]
    [ "krit" "services" "cloud" "googleDrive" ]
    [ "krit" "services" "cloud" "onedrivePersonal" ]
    [ "krit" "services" "cloud" "pcloud" ]
    [ "krit" "services" "cloud" "protonDrive" ]
    [ "krit" "services" "nas" "opencloud-mount" ]
    [ "krit" "services" "nas" "smb" ]
    [ "krit" "services" "nas" "sshfs" ]
    [ "krit" "system" "ssh-config" ]
    [ "services" "external" "dotfiles-private" ]
  ];

  plain = v: lib.concatStringsSep ";" (lib.toList (if v ? _type then v.content else v));
  portalTable = lib.mapAttrs (_: lib.mapAttrs (_: plain)) portalConfig;
  sessionPkgs = h: (spec h).services.displayManager.sessionPackages;
  mangoPkgs = h: lib.filter (p: lib.elem "ryoku-mango" p.providedSessions) (sessionPkgs h);
  otherPkgs = h: lib.filter (p: !(lib.elem "ryoku-mango" p.providedSessions)) (sessionPkgs h);
  linked = h: p: lib.hasInfix (builtins.unsafeDiscardStringContext (toString p)) (builtins.unsafeDiscardStringContext (spec h).services.displayManager.sessionData.desktops.buildCommand);
  portalOk = h: (spec h).xdg.portal.config == portalTable;
  secretOnce = h: lib.all (d: (spec h).xdg.portal.config.${d}."org.freedesktop.impl.portal.Secret" == "gnome-keyring") [ "hyprland" "niri" "mango" ];

  failingRyoku = h: lib.filter (m: lib.hasPrefix "specializations.ryoku:" m) (map (a: a.message) (lib.filter (a: !a.assertion) h.config.assertions));

  layerNames = lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir (src + "/users")));
  mentionsLayer = text: lib.any (l: lib.hasInfix "${l}." text || lib.hasInfix "\"${l}\"" text || lib.hasInfix "${l}-" text) layerNames;

  persist = c: map (d: d.directory) c.environment.persistence."/persist".directories;
  bobNoImp = bob.extendModules { modules = [{ myconfig.services.impermanence.enable = lib.mkOverride 10 false; }]; };

  hmServices = c: lib.attrNames c.home-manager.users.${c.myconfig.constants.user}.systemd.user.services;
  syncUnits = lib.attrNames probes.repoSyncUnits;
  privName = "ryoku-dotfiles-private-sync";
  svc = c: n: c.home-manager.users.${c.myconfig.constants.user}.systemd.user.services.${n};
  privSvc = c: svc c privName;
  unitText = c: n: builtins.unsafeDiscardStringContext (builtins.readFile (lib.head (lib.toList (svc c n).Service.ExecStart)));
  syncBad = mut: lib.filterAttrs (n: u: probes.repoSyncProblems u (mut (unitText (spec bob) n)) == [ ]) probes.repoSyncUnits;
  tmpMentions = u: lib.filter (r: lib.hasInfix " ${u} " r || lib.hasInfix "/home/${u}/" r);

  flakeText = builtins.readFile (src + "/flake.nix");
  anchor = "{ config, ... }: { home-manager.users.\${config.\${args.myconfigName}.constants.user} = _home; };";

  mkBob = generic: mk { name = "ryoku-bob"; user = "bob"; host = "host-bob.nix"; extra = layer; inherit generic; };
  mkAlice = generic: mk { name = "ryoku-alice"; user = "alice"; host = "host-alice.nix"; inherit generic; };
  ext = h: modules: h.extendModules { inherit modules; };
  settingsOf = h: h.config.myconfig.specializations.ryoku.settings;
  withSettings = h: v: ext h [{ myconfig.specializations.ryoku.settings = v; }];
  storesOf = h: lib.attrNames (lib.filterAttrs (_: v: v != { }) (settingsOf h));
  hasMsg = sub: lib.any (m: lib.hasInfix sub m);
  failingSet = h: lib.filter (m: lib.hasPrefix "specializations.ryoku.settings" m) (map (a: a.message) (lib.filter (a: !a.assertion) h.config.assertions));

  sddmSeedOf = h: (spec h).systemd.services.ryoku-sddm-theme-seed or null;
  seedOk = u:
    u != null && u.serviceConfig.Type == "oneshot" && lib.elem "display-manager.service" u.before
    && lib.elem "display-manager.service" u.wantedBy && lib.elem "/var/lib/ryoku" (lib.toList u.unitConfig.RequiresMountsFor);
  noSddm = ext bob [{ services.displayManager.sddm.enable = lib.mkOverride 10 false; }];
  noImpGate = mkBob (mutate "config.myconfig.services.impermanence.enable && " "" genericText);
  noImpGateOff = ext noImpGate [{ myconfig.services.impermanence.enable = lib.mkOverride 10 false; }];
  noBeforeDm = mkBob (mutate "before = [ \"display-manager.service\" ];" "before = [ ];" genericText);

  unitOf = h: (spec h).systemd.user.services.ryoku-settings-seed or null;
  unitOk = h: u: u != null
    && lib.elem "ryoku-materialize.service" u.after && lib.elem "ryoku-materialize.service" u.requires
    && lib.elem "ryoku-shell.service" u.before && lib.elem "ryoku-session.target" u.wantedBy
    && (u.unitConfig.ConditionUser or null) == ryokuUser h && u.serviceConfig.Type == "oneshot";
  execText = h: builtins.readFile (unitOf h).serviceConfig.ExecStart;
  hashOf = h: st:
    let m = lib.concatMap (l: let r = builtins.match ".*seed ${st} /nix/store/[^ ]+ ([0-9a-f]{16})[ ;].*" l; in lib.optional (r != null) (builtins.head r)) (lib.splitString "\n" (execText h)); in
    if m == [ ] then null else builtins.head m;
  emblemUnitOf = h: (spec h).systemd.user.services.ryoku-fastfetch-emblem-seed or null;
  emblemOk = h: u: u != null
    && lib.elem "ryoku-materialize.service" u.after && lib.elem "ryoku-materialize.service" u.requires
    && lib.elem "ryoku-shell.service" u.before && lib.elem "ryoku-session.target" u.wantedBy
    && (u.unitConfig.ConditionUser or null) == ryokuUser h && u.serviceConfig.Type == "oneshot";
  emblemScriptOk = u: u != null && (
    let t = builtins.readFile u.serviceConfig.ExecStart; in
    lib.hasInfix "fastfetch import-logo" t && lib.hasInfix "fastfetch-emblem-" t && probes.sentinelAfterSave t
  );
  aliceEmblem = ext alice [{ myconfig.specializations.ryoku.fastfetchEmblem = pkgs.writeText "emblem.png" "x"; }];
  sentinelLine = "    ${"$"}{coreutils}/rm -f \"$state/fastfetch-emblem-\"*\n    : > \"$sentinel\"\n";
  noSentinel = mkAlice (mutate sentinelLine "" genericText);
  sentinelFirst = mkAlice (load (repl "    \${hub} fastfetch save \"$model\"" "    : > \"$sentinel\"\n    \${hub} fastfetch save \"$model\"" (repl sentinelLine "" genericText)));
  aliceNoSentinel = ext noSentinel [{ myconfig.specializations.ryoku.fastfetchEmblem = pkgs.writeText "emblem.png" "x"; }];
  aliceSentinelFirst = ext sentinelFirst [{ myconfig.specializations.ryoku.fastfetchEmblem = pkgs.writeText "emblem.png" "x"; }];
  cursorOpts = { myconfig.specializations.ryoku = { sddmCursorTheme = "Test-Cursor"; sddmCursorPackage = pkgs.hello; sddmCursorSize = 32; }; };
  aliceCursor = ext alice [ cursorOpts ];
  aliceKwin = ext alice [ cursorOpts { services.displayManager.sddm.wayland.compositor = "kwin"; } ];
  noWestonCmd = mkAlice (mutate "lib.mkIf (cfg.sddmCursorTheme != null && dm.sddm.wayland.compositor == \"weston\")" "lib.mkIf false" genericText);
  aliceNoWestonCmd = ext noWestonCmd [ cursorOpts ];
  westonCmd = h: (spec h).services.displayManager.sddm.wayland.compositorCommand;
  westonProblems = h: probes.westonCursorProblems { theme = "Test-Cursor"; size = 32; cmd = westonCmd h; };
  wrapperText = h: let n = lib.filter (p: lib.getName p == "ryoku-fastfetch") (hmCfg h).home.packages; in if n == [ ] then null else builtins.readFile "${lib.head n}/bin/ryoku-fastfetch";
  wrapperBad = from: to: probes.fastfetchWrapperProblems (lib.replaceStrings [ from ] [ to ] (wrapperText bob)) != [ ];
  noXcursor = mkAlice (mutate "++ [ \"XCURSOR_PATH=/run/current-system/sw/share/icons\" ]" "" genericText);
  aliceNoXcursor = ext noXcursor [ cursorOpts ];
  sddmSet = h: (spec h).services.displayManager.sddm.settings;
  cursorTheme = h: lib.attrByPath [ "Theme" "CursorTheme" ] null (sddmSet h);
  greeterEnv = h: lib.splitString "," (lib.attrByPath [ "General" "GreeterEnvironment" ] "" (sddmSet h));
  xcursorEntry = "XCURSOR_PATH=/run/current-system/sw/share/icons";
  cursorApplied = h: cursorTheme h != null && lib.elem xcursorEntry (greeterEnv h);
  aliceEmpty = ext alice [{ myconfig.specializations.ryoku.settings = lib.mkOverride 10 { }; }];
  rtSettings = {
    desktop.desktop.appearance = { gapsIn = 6; gapsOut = 12; };
    shell = { fontFamily = "Test"; clipboard.pruneWeekly = true; };
    theme.scheme = "mono";
  };
  aliceA = withSettings alice rtSettings;
  aliceB = withSettings alice (rtSettings // { theme.scheme = "light"; });
  aliceE = ext aliceA [{ myconfig.specializations.ryoku.settingsMode = "enforce"; }];
  realised = h: let p = toString (unitOf h).serviceConfig.ExecStart; in builtins.seq (builtins.readFile p) p;
  aliceHub = withSettings alice { hub.x = 1; };
  aliceI18n = withSettings alice { i18n-llm.x = 1; };
  aliceBogus = withSettings alice { bogus.x = 1; };
  aliceLoc = withSettings alice { shell.python.general.location = "x"; };
  aliceOkSet = withSettings alice { shell.fontFamily = "x"; };
  noSecretAssert = withSettings (mkAlice (mutate "secretStores = [ \"hub\" \"i18n-llm\" ];" "secretStores = [ ];" genericText)) { hub.x = 1; };
  noUnknownAssert = withSettings (mkAlice (mutate "assertion = lib.all (n: lib.elem n settingsStores) (lib.attrNames cfg.settings);" "assertion = true;" genericText)) { bogus.x = 1; };
  noLocAssert = withSettings (mkAlice (mutate "assertion = !(lib.hasAttrByPath [ \"python\" \"general\" \"location\" ] (cfg.settings.shell or { }));" "assertion = true;" genericText)) { shell.python.general.location = "x"; };
  noCondUser = mkAlice (mutateBoth "unitConfig.ConditionUser = user;" "" genericText);
  noBeforeShell = mkAlice (mutateBoth "before = [ \"ryoku-shell.service\" ];" "before = [ ];" genericText);
  noAfterMat = mkAlice (mutateBoth "after = [ \"ryoku-materialize.service\" ];" "after = [ ];" genericText);

  appsOf = h: h.config.myconfig.specializations.ryoku.settings.desktop.desktop.apps;
  constOf = h: h.config.myconfig.constants;
  expectApps = h:
    let
      c = constOf h;
      inTerm = app: if lib.elem app c.terminalApps then "${c.terminal.name} -e ${app}" else app;
    in
    { inherit (c) browser; terminal = c.terminal.name; editor = inTerm c.editor; files = inTerm c.fileManager; notes = inTerm c.editor; };
  withConst = h: v: ext h [{ myconfig.constants = lib.mapAttrsRecursive (_: lib.mkOverride 10) v; }];
  appsTerm = withConst alice { terminal.name = "kitty"; editor = "nvim"; fileManager = "yazi"; browser = "fox"; };
  appsGui = withConst alice { terminal.name = "kitty"; editor = "code"; fileManager = "dolphin"; browser = "fox"; };
  appsFoot = withConst alice { terminal.name = "foot"; editor = "nvim"; fileManager = "yazi"; browser = "fox"; };
  appsOverride = ext appsTerm [{ myconfig.specializations.ryoku.settings.desktop.desktop.apps.browser = "mine"; }];
  hardKitty = mkAlice (mutate "then \"\${constants.terminal.name} -e \${app}\"" "then \"kitty -e \${app}\"" genericText);
  hardKittyFoot = withConst hardKitty { terminal.name = "foot"; editor = "nvim"; fileManager = "yazi"; browser = "fox"; };

  hmCfg = h: (spec h).home-manager.users.${ryokuUser h};
  hmF = h: (hmCfg h).xdg.configFile;
  bindFiles = [ "hypr/user.lua" "niri/user.kdl" ];
  binT = h: { hypr = (hmF h)."hypr/user.lua".text; niri = (hmF h)."niri/user.kdl".text; };
  bobT = binT bob;
  extraMods = [{
    myconfig.programs = {
      hyprland.extraBinds = [{ _args = [ "SUPER + F12" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }];
      niri.extraBinds."Mod+F12".action.close-window = [ ];
    };
  }];
  bobExtraT = binT (ext bob extraMods);
  bobDupT = binT (ext bob [{
    myconfig.programs = {
      hyprland.extraBinds = [
        { _args = [ "SUPER + F12" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
        { _args = [ "SUPER + F12" (lib.generators.mkLuaInline "hl.dsp.window.close()") ]; }
      ];
    };
  }]);
  noForceBinds = mk {
    name = "ryoku-bob";
    user = "bob";
    host = "host-bob.nix";
    extra = layer;
    bindsModule = load (repl "\"hypr/user.lua\" = {\n            force = true;" "\"hypr/user.lua\" = {\n            force = false;" bindsText);
  };
  legacyBinds = mk {
    name = "ryoku-bob";
    user = "bob";
    host = "host-bob.nix";
    extra = layer;
    bindsModule = load (repl "shell = ryokuProfile { home = config.users.users.\${user}.home; };" "shell = (ryokuProfile { home = config.users.users.\${user}.home; }) // { launcher = \"vicinae toggle\"; };" bindsText);
  };

  binds = src + "/modules/nixos/programs/de-wm/binds-lib";
  libConstants = { terminal.name = "term"; browser = "web"; fileManager = "fm"; editor = "ed"; terminalApps = [ "fm" ]; };
  libShell = {
    launcher = "launch";
    menu = "menu";
    lock = "lock";
    emoji = "emoji";
    clipboard = "clip";
    picker = "pick";
    reload = "reload";
    notifications = "notif";
    barReload = "br";
    barToggle = "bt";
    screenshotScreen = "shots";
    screenshotArea = "shota";
    volumeUp = "vu";
    volumeDown = "vd";
    volumeMute = "vm";
    micMute = "mm";
    brightnessUp = "bu";
    brightnessDown = "bd";
    kbdBrightnessUp = "ku";
    kbdBrightnessDown = "kd";
    mediaPlay = "mp";
    mediaNext = "mn";
    mediaPrev = "mv";
    mediaStop = "ms";
    capsLock = "cl";
  };
  hyprLib = shell: import (binds + "/hyprland.nix") { inherit lib; } { constants = libConstants; inherit shell; };
  niriLib = import (binds + "/niri.nix") { inherit lib; } { constants = libConstants; shell = libShell; };
  mangoLib = import (binds + "/mango.nix") { inherit lib; } { constants = libConstants; shell = libShell; pip = "pip"; };
  hyprChords = map (b: builtins.head b._args) (hyprLib libShell);

  guard = "set -q __fish_home_manager_config_sourced; and exit";
  userFish = h: builtins.readFile (hmF h)."fish/user.fish".source;
  noFishSed = mkBob (mutate "'/^set -q __fish_home_manager_config_sourced; and exit$/d'" "'/^NOMATCH$/d'" genericText);
  noYaziVar = mkBob (mutate "home.sessionVariables.YAZI_CONFIG_HOME = \"\${config.home.homeDirectory}/.config/yazi-user\";" "" genericText);
  yaziWant = h: "${(usersOf (spec h)).${ryokuUser h}.home}/.config/yazi-user";

  hmTargetsOn = h: lib.sort (a: b: a < b) (lib.attrNames (lib.filterAttrs (n: _: (hmCfg h).stylix.targets.${n}.enable or false == true) (hmCfg h).stylix.targets));
  stylixOn = [ "bat" "blender" "cava" "fzf" "gdu" "gedit" "lazygit" "nixcord" "tmux" "zathura" "zen-browser" ];
  stylixOff = [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" "fontconfig" "font-packages" "nixos-icons" ];
  noGtkOff = mkBob (mutate "stylixLiteOff = [ \"gtk\" " "stylixLiteOff = [ " genericText);
  noEza = mkBob (mutate "catppuccin.eza.enable = lib.mkForce true;" "catppuccin.eza.enable = lib.mkForce false;" genericText);

  inputOf = h: h.config.myconfig.specializations.ryoku.settings.desktop.desktop.input;
  kbTwin = withConst alice { keyboardLayout = "de,us"; keyboardVariant = "nodeadkeys,"; keyboardOptions = "grp:ctrl_alt_toggle"; };
  kbEmpty = withConst alice { keyboardLayout = "us"; keyboardVariant = ""; keyboardOptions = "grp:ctrl_alt_toggle"; };
  kbOverride = ext kbTwin [{ myconfig.specializations.ryoku.settings.desktop.desktop.input = { naturalScroll = true; kbLayout = "fr"; }; }];
  wholeLayout = mkAlice (mutate "kbLayout = firstEntry constants.keyboardLayout;" "kbLayout = constants.keyboardLayout;" genericText);
  wholeLayoutTwin = withConst wholeLayout { keyboardLayout = "de,us"; keyboardVariant = "nodeadkeys,"; keyboardOptions = "grp:ctrl_alt_toggle"; };

  lightMods = [{ myconfig.constants.theme.polarity = lib.mkOverride 10 "light"; }];
  bobLight = ext bob lightMods;
  bobLightOther = ext bobLight [{
    myconfig.specializations.ryoku.settings = {
      shell.theme.theme = lib.mkForce "NotInTheTable";
      ryogami.theme.staticTheme = lib.mkForce "NotInTheTable";
    };
  }];
  noPolarityAssert = ext (mkBob (mutate "assertion = lib.all (n: (staticPolarity.\${n} or constants.theme.polarity) == constants.theme.polarity) declaredStaticThemes;" "assertion = true;" genericText)) lightMods;
  mkBobLayer = text: mk { name = "ryoku-bob"; user = "bob"; host = "host-bob.nix"; extra = [ (load text) (here + "/krit-option-sinks.nix") ]; };
  hardDark = ext (mkBobLayer (repl "        mode = polarity;\n        schemeType" "        mode = \"dark\";\n        schemeType" layerText)) lightMods;
  idleOf = h: (settingsOf h).power.idle;
  stageTimes = st: { inherit (st) dimSec lockSec screenOffSec; };
  hyTimes = { myconfig.services.hypridle = { dimTimeout = 111; lockTimeout = 222; screenOffTimeout = 333; }; };
  bobHy = ext bob [ hyTimes ];
  bobNoSusp = ext bob [{ myconfig.specializations.ryoku.settings.power.idle = { battery.suspendSec = 0; ac.suspendSec = 0; }; }];
  hardIdle = ext (mkBobLayer (repl "dimSec = hypridle.dimTimeout;" "dimSec = 300;" layerText)) [ hyTimes ];
  noSuspDefault = ext (mkBobLayer (repl "suspendSec = lib.mkDefault suspendSec;" "inherit suspendSec;" layerText)) [{ myconfig.specializations.ryoku.settings.power.idle = { battery.suspendSec = 0; ac.suspendSec = 0; }; }];
  alicePower = withSettings alice { power.idle.enabled = true; };
  noPowerStore = withSettings (mkAlice (mutate "    \"power\"\n" "" genericText)) { power.idle.enabled = true; };
  matugenOf = h: (settingsOf h).matugen;
  aliceLayer = mk { name = "ryoku-alice"; user = "alice"; host = "host-alice.nix"; extra = layer; };
  heroOf = h: (settingsOf h).launcher.heroImage;

  checks = {
    "control: the fixture's home-user-follows-constants mirrors flake.nix" =
      yes "flake.nix no longer carries the extension body the fixture copies (fixture/home-user-follows-constants.nix)"
        (lib.hasInfix anchor flakeText && lib.hasInfix anchor (builtins.readFile (here + "/home-user-follows-constants.nix")));
    "fixture: bob spec exists, tagged ryoku, programs.ryoku on in the spec only" =
      yes "ryoku spec missing, untagged, or programs.ryoku enable wrong"
        (builtins.elem "ryoku" (spec bob).system.nixos.tags && (spec bob).programs.ryoku.enable && !bob.config.programs.ryoku.enable);
    "fixture: spec user is <base user>-ryoku and differs from the base user" =
      yes "user ${ryokuUser bob} for base ${baseUser bob}" (ryokuUser bob == "${baseUser bob}-ryoku" && ryokuUser bob != baseUser bob);
    "fixture: uid is not the base uid, subuid and subgid ranges do not overlap the base ranges" =
      let
        u = (usersOf (spec bob)).${ryokuUser bob};
        b = (usersOf bob.config).${baseUser bob};
        ok = k: rangesOf u k != [ ] && rangesOf b k != [ ] && !(overlaps (rangesOf u k) (rangesOf b k));
      in
      yes "uid ${toString u.uid} vs ${toString b.uid}, ranges ${builtins.toJSON (rangesOf u "subUidRanges")} vs ${builtins.toJSON (rangesOf b "subUidRanges")}"
        (u.uid != b.uid && ok "subUidRanges" && ok "subGidRanges");
    "control: the range overlap probe flags overlap and accepts disjoint ranges" =
      yes "overlap probe is wrong"
        (overlaps [{ start = 100; count = 50; }] [{ start = 120; count = 10; }] && !(overlaps [{ start = 100; count = 50; }] [{ start = 150; count = 10; }]));
    "fixture: the base user does not exist in the spec, the base has it (control)" =
      yes "spec users ${builtins.toJSON (lib.attrNames (usersOf (spec bob)))}, base ${builtins.toJSON (lib.attrNames (usersOf bob.config))}"
        (!((usersOf (spec bob)) ? ${baseUser bob}) && (usersOf bob.config) ? ${baseUser bob} && (usersOf (spec bob)) ? ${ryokuUser bob});
    "fixture: home-manager.users is exactly the new user in the spec and the base user in the base" =
      eq "hm users" [ (hmUsers (spec bob)) (hmUsers bob.config) ] [ [ (ryokuUser bob) ] [ (baseUser bob) ] ];
    "fixture: no tmpfiles rule in the spec names the base user's home, the base's own rule does (control)" =
      yes "spec rules naming ${baseUser bob}: ${builtins.toJSON (tmpMentions (baseUser bob) (spec bob).systemd.tmpfiles.rules)}"
        (tmpMentions (baseUser bob) (spec bob).systemd.tmpfiles.rules == [ ] && tmpMentions (baseUser bob) bob.config.systemd.tmpfiles.rules != [ ]);
    "fixture: the spec home is created for the new user and owned by it" =
      let
        home = (usersOf (spec bob)).${ryokuUser bob}.home;
        rules = lib.filter (r: lib.hasPrefix "d ${home} " r) (spec bob).systemd.tmpfiles.rules;
      in
      yes "home rule ${builtins.toJSON rules}" (lib.length rules == 1 && lib.hasInfix " ${ryokuUser bob} " (lib.head rules) && home == "/home/${ryokuUser bob}");

    "fixture: another base user (alice) still gives a working spec: user alice-ryoku" =
      eq "alice spec user" (ryokuUser alice) "alice-ryoku";
    "fixture: alice spec has its own uid, no alice and no bob user, home-manager users [ alice-ryoku ]" =
      let u = (usersOf (spec alice)).${ryokuUser alice}; in
      yes "users ${builtins.toJSON (lib.attrNames (usersOf (spec alice)))}, hm ${builtins.toJSON (hmUsers (spec alice))}, uid ${toString u.uid}"
        (u.uid != (usersOf alice.config).alice.uid && !((usersOf (spec alice)) ? alice) && !((usersOf (spec alice)) ? ${baseUser bob}) && hmUsers (spec alice) == [ "alice-ryoku" ]);
    "control: the two fixture bases differ, so the portability check cannot pass on a fixed name" =
      yes "bases ${baseUser bob} / ${baseUser alice}" (baseUser bob != baseUser alice && ryokuUser bob != ryokuUser alice);

    "fixture: every explicitly forced-off option is false in the spec while the base has it on" = forcedOff offPaths bob;
    "fixture: constants.theme.catppuccin is false in the spec, true in the base" =
      yes "catppuccin ${builtins.toJSON [ bob.config.myconfig.constants.theme.catppuccin (spec bob).myconfig.constants.theme.catppuccin ]}"
        (bob.config.myconfig.constants.theme.catppuccin && !(spec bob).myconfig.constants.theme.catppuccin);
    "mutant: dropping vicinae from the force-off list is detected" =
      yes "the force-off probe does not notice a missing entry" (failed (forcedOff offPaths noVicinaeOff));
    "control: the force-off probe rejects a base that does not have the option on" =
      yes "probe accepted a base without the options" (failed (forcedOff offPaths (bob // { config = bob.config // { myconfig = bob.config.myconfig // { qt = { enable = false; }; }; }; })));

    "fixture: spec portal config equals the repo portal table, Secret routed to gnome-keyring once in hyprland, niri and mango" =
      yes "xdg.portal.config differs from xdg-portal-config.nix" (portalOk bob && secretOnce bob);
    "mutant: without the portal mkForce the Ryoku fragments duplicate entries (detected)" =
      yes "mutant still matches the table" (!(portalOk noPortalForce) || !(secretOnce noPortalForce));

    "fixture: the session data offers ryoku-hyprland and ryoku-niri, not ryoku-mango, and does not autologin into it; the spec still receives the ryoku-mango package (control)" =
      let sd = (spec bob).services.displayManager.sessionData; in
      yes "sessionNames ${builtins.toJSON sd.sessionNames}, packages ${builtins.toJSON (map (p: p.providedSessions) (sessionPkgs bob))}"
        (lib.sort lib.lessThan (lib.unique (lib.filter (lib.hasPrefix "ryoku-") sd.sessionNames)) == [ "ryoku-hyprland" "ryoku-niri" ] && sd.autologinSession != "ryoku-mango" && mangoPkgs bob != [ ]);
    "fixture: the session desktops derivation links the other session packages and leaves the ryoku-mango one out (by build command)" =
      yes "linked mango ${builtins.toJSON (map (linked bob) (mangoPkgs bob))}, others ${builtins.toJSON (map (linked bob) (otherPkgs bob))}"
        (otherPkgs bob != [ ] && mangoPkgs bob != [ ] && lib.all (p: !(linked bob p)) (mangoPkgs bob) && lib.all (linked bob) (otherPkgs bob));
    "mutant: without the ryoku-mango session filter the session data lists ryoku-mango and links its package (detected)" =
      yes "mutant names ${builtins.toJSON (spec noMangoFilter).services.displayManager.sessionData.sessionNames}"
        (lib.elem "ryoku-mango" (spec noMangoFilter).services.displayManager.sessionData.sessionNames && lib.all (linked noMangoFilter) (mangoPkgs noMangoFilter) && mangoPkgs noMangoFilter != [ ]);
    "fixture: x86_64 with the spec on: no ryoku assertion fails and programs.ryoku is on" =
      eq "x86 failing ryoku assertions / enable" [ (failingRyoku bob) (spec bob).programs.ryoku.enable ] [ [ ] true ];
    "fixture: aarch64 with the spec on: the arch assertion fails with its message and programs.ryoku stays off" =
      yes "aarch64 failing ryoku assertions ${builtins.toJSON (failingRyoku arm)}, enable ${builtins.toJSON (spec arm).programs.ryoku.enable}"
        (lib.length (failingRyoku arm) == 1 && lib.hasInfix "x86_64" (lib.head (failingRyoku arm)) && !(spec arm).programs.ryoku.enable);
    "mutant: without the arch assertion the aarch64 fixture reports no failing ryoku assertion (detected)" =
      yes "mutant still reports the assertion" (failingRyoku noX86Assertion == [ ]);

    "fixture: /var/lib/ryoku is persisted in the spec when impermanence is on" =
      yes "persist ${builtins.toJSON (persist (spec bob))}" (lib.elem "/var/lib/ryoku" (persist (spec bob)) && !(lib.elem "/var/lib/ryoku" (persist bob.config)));
    "control: with impermanence off the spec persists nothing" =
      yes "persist leaked" (!(bobNoImp.config.environment.persistence ? "/persist") || !(lib.elem "/var/lib/ryoku" (persist bobNoImp.config.specialisation.ryoku.configuration)));

    "layer: with the user layer loaded the spec has both clone services" =
      yes "units ${builtins.toJSON (hmServices (spec bob))}" (lib.all (n: lib.elem n (hmServices (spec bob))) syncUnits);
    "layer: the base host (not the spec) has neither clone service" =
      yes "base has them" (!(lib.any (n: lib.elem n (hmServices bob.config)) syncUnits));
    "layer: without the user layer the spec has no clone service" =
      yes "alice spec units ${builtins.toJSON (hmServices (spec alice))}" (!(lib.any (n: lib.elem n (hmServices (spec alice))) syncUnits));
    "layer: the three repo sync units are one-shot, on-failure, not start-limited, default.target" =
      yes "unit settings differ"
        (lib.all (n: let u = svc (spec bob) n; in u.Service.Type == "oneshot" && u.Service.Restart == "on-failure" && u.Unit.StartLimitIntervalSec == 0 && u.Install.WantedBy == [ "default.target" ]) syncUnits);
    "layer: the three repo sync scripts have the required guards, the right url and transport and none of the destructive commands" =
      yes "problems ${builtins.toJSON (lib.mapAttrs (n: u: probes.repoSyncProblems u (unitText (spec bob) n)) probes.repoSyncUnits)}"
        (lib.all (n: probes.repoSyncProblems probes.repoSyncUnits.${n} (unitText (spec bob) n) == [ ]) syncUnits);
    "mutant: every repo sync script with reset --hard instead of the ff-only merge is detected" =
      yes "probe silent for ${toString (lib.attrNames (syncBad (lib.replaceStrings [ "merge --quiet --ff-only" ] [ "reset --hard" ])))}"
        (syncBad (lib.replaceStrings [ "merge --quiet --ff-only" ] [ "reset --hard" ]) == { });
    "mutant: every repo sync script without the porcelain dirty guard is detected" =
      yes "probe silent" (syncBad (lib.replaceStrings [ "status --porcelain" ] [ "status" ]) == { });
    "mutant: every repo sync script with a rm -rf of the target dir is detected" =
      yes "probe silent" (syncBad (lib.replaceStrings [ "rm -rf \"$tmp\"" ] [ "rm -rf \"$dir\"" ]) == { });
    "mutant: every repo sync script with a shallow clone is detected" =
      yes "probe silent" (syncBad (lib.replaceStrings [ "clone --quiet" ] [ "clone --depth 1 --quiet" ]) == { });
    "mutant: every repo sync script without the unshallow healing is detected" =
      yes "probe silent" (syncBad (lib.replaceStrings [ "--unshallow" ] [ "--prune" ]) == { });
    "mutant: the public repo sync scripts with an ssh url or the private one with an https url are detected" =
      yes "probe silent"
        (probes.repoSyncProblems probes.repoSyncUnits.ryoku-dotfiles-sync (lib.replaceStrings [ "https://github.com/" ] [ "ssh://git@gitea-ssh.nicolkrit.ch:2222/" ] (unitText (spec bob) "ryoku-dotfiles-sync")) != [ ]
          && probes.repoSyncProblems probes.repoSyncUnits.${privName} (lib.replaceStrings [ "ssh://git@gitea-ssh.nicolkrit.ch:2222/krit/" ] [ "https://github.com/nicolkrit999/" ] (unitText (spec bob) privName)) != [ ]);
    "layer: only the borg modules are forced off in the spec (base twin has them on)" =
      let
        baseNotOn = lib.filter (p: optOf bob.config p != true) borgPaths;
        stillOn = lib.filter (p: optOf (spec bob) p != false) borgPaths;
      in
      yes "base lacks ${toString (map showPath baseNotOn)}, still on ${toString (map showPath stillOn)}" (baseNotOn == [ ] && stillOn == [ ]);
    "audit: the personal re-enable list (ssh config, clouds, NAS mounts, home base, private dotfiles) stays on in the spec like in the base" =
      let
        lost = lib.filter (p: optOf (spec bob) p != true) reenablePaths;
        baseNotOn = lib.filter (p: optOf bob.config p != true) reenablePaths;
      in
      yes "base lacks ${toString (map showPath baseNotOn)}, off in the spec ${toString (map showPath lost)}" (baseNotOn == [ ] && lost == [ ]);
    "control: a re-enable probe applied to the borg list flags it (they are off in the spec)" =
      yes "probe cannot fail" (lib.filter (p: optOf (spec bob) p != true) borgPaths != [ ]);
    "layer: wallpapersLink false in the spec and true in the base; the yazi go-to exclusion is left at the base default in both" =
      eq "layer values"
        [ bob.config.myconfig.services.external.dotfiles.wallpapersLink (spec bob).myconfig.services.external.dotfiles.wallpapersLink bob.config.myconfig.krit.programs.yazi.goToExclude (spec bob).myconfig.krit.programs.yazi.goToExclude ]
        [ true false [ ] [ ] ];

    "sddm seed: with impermanence and sddm the spec has a oneshot unit wanted by and Before display-manager, mounts /var/lib/ryoku; the base has none" =
      yes "unit ${builtins.toJSON (sddmSeedOf bob != null)}, base ${builtins.toJSON (bob.config.systemd.services ? ryoku-sddm-theme-seed)}"
        (seedOk (sddmSeedOf bob) && !(bob.config.systemd.services ? ryoku-sddm-theme-seed));
    "sddm seed: the script guards on Main.qml and calls every tool by absolute store path" =
      let t = (sddmSeedOf bob).script; in
      yes "bare tools ${builtins.toJSON (probes.bareToolLines t)}" (lib.hasInfix "Main.qml" t && lib.hasInfix "/nix/store/" t && probes.bareToolLines t == [ ]);
    "sddm seed: absent with impermanence off and absent with sddm off (controls: both on gives the unit)" =
      yes "impermanence off ${builtins.toJSON (sddmSeedOf bobNoImp != null)}, sddm off ${builtins.toJSON (sddmSeedOf noSddm != null)}, both on ${builtins.toJSON (sddmSeedOf bob != null)}"
        (sddmSeedOf bobNoImp == null && sddmSeedOf noSddm == null && sddmSeedOf bob != null);
    "mutant: without the impermanence gate the impermanence-off twin gets the unit (detected)" =
      yes "mutant still has no unit" (sddmSeedOf noImpGateOff != null);
    "mutant: without Before=display-manager the ordering probe fails (detected)" =
      yes "mutant still passes" (!(seedOk (sddmSeedOf noBeforeDm)));

    "settings: the options settings (default {}) and settingsMode (default seed-once) exist" =
      eq "defaults" [ bob.options.myconfig.specializations.ryoku.settings.default bob.options.myconfig.specializations.ryoku.settingsMode.default ] [{ } "seed-once"];
    "settings: with the user layer the declared stores are several, without it only desktop.apps and desktop.input (the layer values are not in the generic module)" =
      yes "bob ${toString (storesOf bob)}, alice ${toString (storesOf alice)} ${builtins.toJSON (settingsOf alice)}"
        (lib.length (storesOf bob) > 1 && storesOf alice == [ "desktop" ] && lib.attrNames (settingsOf alice).desktop == [ "desktop" ] && lib.attrNames (settingsOf alice).desktop.desktop == [ "apps" "input" ]);
    "settings: an empty declaration generates no unit; a declared one does (control)" =
      yes "empty ${builtins.toJSON (unitOf aliceEmpty != null)}, declared ${builtins.toJSON (unitOf alice != null)}" (unitOf aliceEmpty == null && unitOf alice != null);
    "settings: the unit is ordered after ryoku-materialize, before ryoku-shell, wanted by ryoku-session.target, ConditionUser is each spec user" =
      yes "bob ${builtins.toJSON (unitOk bob (unitOf bob))}, alice ${builtins.toJSON (unitOk alice (unitOf alice))}, bob cond ${builtins.toJSON (unitOf bob).unitConfig.ConditionUser or null}"
        (unitOk bob (unitOf bob) && unitOk alice (unitOf alice) && (unitOf bob).unitConfig.ConditionUser == "bob-ryoku" && (unitOf alice).unitConfig.ConditionUser == "alice-ryoku");
    "mutant: without ConditionUser, Before ryoku-shell or After ryoku-materialize the unit probe fails (detected)" =
      yes "a mutant still passes: ${builtins.toJSON [ (unitOk noCondUser (unitOf noCondUser)) (unitOk noBeforeShell (unitOf noBeforeShell)) (unitOk noAfterMat (unitOf noAfterMat)) ]}"
        (!(unitOk noCondUser (unitOf noCondUser)) && !(unitOk noBeforeShell (unitOf noBeforeShell)) && !(unitOk noAfterMat (unitOf noAfterMat)));
    "sddm cursor: the options default to null, null and 24, and without them (alice, no krit layer) the sddm settings have no cursor theme and no XCURSOR_PATH" =
      yes "defaults ${builtins.toJSON (let o = alice.config.myconfig.specializations.ryoku; in [ o.sddmCursorTheme (o.sddmCursorPackage != null) o.sddmCursorSize ])}, theme ${builtins.toJSON (cursorTheme alice)}, env ${builtins.toJSON (greeterEnv alice)}"
        (alice.config.myconfig.specializations.ryoku.sddmCursorTheme == null && alice.config.myconfig.specializations.ryoku.sddmCursorPackage == null
          && alice.config.myconfig.specializations.ryoku.sddmCursorSize == 24
          && cursorTheme alice == null && !(lib.elem xcursorEntry (greeterEnv alice))
          && !(sddmSet alice ? Theme && sddmSet alice.Theme ? CursorSize));
    "sddm cursor: with the krit layer (bob) the spec gets Bibata-Modern-Ice, size 24, XCURSOR_PATH and the package (control)" =
      yes "theme ${builtins.toJSON (cursorTheme bob)}, env ${builtins.toJSON (greeterEnv bob)}"
        (cursorTheme bob == "Bibata-Modern-Ice" && (sddmSet bob).Theme.CursorSize == 24 && cursorApplied bob
          && lib.any (p: (p.pname or "") == "bibata-cursors") (spec bob).environment.systemPackages);
    "sddm cursor: a host declaring the options gets theme, size, XCURSOR_PATH, the package and /share/icons; weston adds no layer-shell" =
      yes "theme ${builtins.toJSON (cursorTheme aliceCursor)}, env ${builtins.toJSON (greeterEnv aliceCursor)}"
        (cursorTheme aliceCursor == "Test-Cursor" && (sddmSet aliceCursor).Theme.CursorSize == 32
          && greeterEnv aliceCursor == [ xcursorEntry ]
          && lib.elem (toString pkgs.hello) (map toString (spec aliceCursor).environment.systemPackages)
          && lib.elem "/share/icons" (spec aliceCursor).environment.pathsToLink);
    "sddm cursor: the kwin compositor keeps QT_WAYLAND_SHELL_INTEGRATION=layer-shell merged ahead of XCURSOR_PATH" =
      eq "GreeterEnvironment" (greeterEnv aliceKwin) [ "QT_WAYLAND_SHELL_INTEGRATION=layer-shell" xcursorEntry ];
    "mutant: GreeterEnvironment without XCURSOR_PATH is detected by the probe" =
      yes "mutant still applied: ${builtins.toJSON (greeterEnv aliceNoXcursor)}" (!(cursorApplied aliceNoXcursor) && cursorApplied aliceCursor);
    "weston cursor: a weston host declaring the cursor options gets the env-wrapped kiosk command and a weston.ini with [shell] cursor-theme/size plus the nixpkgs sections" =
      let
        cmd = westonCmd aliceCursor;
        ini = builtins.readFile (lib.last (lib.splitString " " cmd));
      in
      yes "problems ${builtins.toJSON (westonProblems aliceCursor)}, ini ${ini}"
        (westonProblems aliceCursor == [ ] && lib.hasInfix "[shell]" ini && lib.hasInfix "cursor-theme=Test-Cursor" ini && lib.hasInfix "cursor-size=32" ini
          && lib.hasInfix "[libinput]" ini && lib.hasInfix "[keyboard]" ini);
    "weston cursor: without the options (alice) the command is the nixpkgs default; the kwin compositor keeps its own command" =
      yes "alice ${westonCmd alice}, kwin ${westonCmd aliceKwin}"
        (!(lib.hasInfix "XCURSOR_THEME" (westonCmd alice)) && !(lib.hasInfix "XCURSOR_THEME" (westonCmd aliceKwin)) && !(lib.hasInfix "env" (lib.head (lib.splitString " " (westonCmd aliceKwin)))));
    "weston cursor: with the krit layer (bob) the spec command carries Bibata-Modern-Ice at size 24 (control)" =
      yes "bob ${westonCmd bob}"
        (probes.westonCursorProblems { theme = "Bibata-Modern-Ice"; size = 24; cmd = westonCmd bob; } == [ ] && !(lib.hasInfix "XCURSOR_THEME" bob.config.services.displayManager.sddm.wayland.compositorCommand));
    "mutant: without the compositorCommand block the weston host keeps the plain command and the probe flags it" =
      yes "mutant command ${westonCmd aliceNoWestonCmd}" (westonProblems aliceNoWestonCmd != [ ] && westonProblems aliceCursor == [ ]);
    "fastfetch: bob (krit layer) has the ryoku-fastfetch wrapper with the absolute real path and both branches, alice (no layer) has none" =
      yes "bob problems ${builtins.toJSON (if wrapperText bob == null then null else probes.fastfetchWrapperProblems (wrapperText bob))}, alice ${builtins.toJSON (wrapperText alice != null)}"
        (wrapperText bob != null && probes.fastfetchWrapperProblems (wrapperText bob) == [ ] && wrapperText alice == null);
    "mutant: a wrapper without the --logo-type none branch, the TMUX test, the tmux-kitty placeholder pipeline, the flattened sprite fallback or the non-image logo-type passthrough is detected" =
      yes "probe silent" (wrapperBad "logo=(--logo-type none)" "logo=()" && wrapperBad "[ -z \"${"$"}{TMUX:-}\" ]" "true"
        && wrapperBad "--unicode-placeholder" "" && wrapperBad "--logo-type file-raw" "--logo-type file" && wrapperBad "\"flat2 $src" "\"$src"
        && wrapperBad "/bin/magick \"$src\" -background" "/bin/true \"$src\" -background"
        && wrapperBad "*) exec \"$real\" \"$@\" ;;" "*) ;;"
        && wrapperBad "--logo-type none --logo-padding-left 0" "--logo-type none"
        && wrapperBad "--logo-padding-right 0 --logo-padding-top 0 --pipe false" "--logo-padding-right 0 --logo-padding-top 0"
        && wrapperBad "--pipe false" "--pipe false --logo \"$rows\" --logo-type file-raw"
        && wrapperBad "jq -r '.logo.padding.left" "jq -r '.logo.pad.left"
        && wrapperBad "jq -r '.logo.padding.right" "jq -r '.logo.pad.right"
        && wrapperBad "jq -r '.logo.padding.top" "jq -r '.logo.pad.top"
        && wrapperBad "print \" \" x $lp, $row, \" \" x $rp, $_" "print $_"
        && wrapperBad "s/\\e\\[(\\d+)G/\"\\e[\" . ($off + ($maxk > $1 ? $maxk : $1) + 2) . \"G\"/ge" ""
        && wrapperBad "($off + ($maxk > $1 ? $maxk : $1) + 2)" "($off + $1 + 2)"
        && wrapperBad "($off + ($maxk > $1 ? $maxk : $1) + 2)" "($off + ($maxk > $1 ? $maxk : $1) + 0)"
        && wrapperBad "my $vc = ($maxk > $kw ? $maxk : $kw) + 1;" "my $vc = 0;"
        && wrapperBad "$_ = (\" \" x $vc) . $_ if $v =~ /\\S/" "");
    "emblem: the option defaults to null and the unit does not exist without it (alice, no krit layer)" =
      yes "default ${builtins.toJSON alice.config.myconfig.specializations.ryoku.fastfetchEmblem}, unit ${builtins.toJSON (emblemUnitOf alice != null)}"
        (alice.config.myconfig.specializations.ryoku.fastfetchEmblem == null && emblemUnitOf alice == null);
    "emblem: the krit layer (bob) leaves the option null, so there is no unit (control against the old hawk.png default)" =
      yes "bob ${builtins.toJSON (bob.config.myconfig.specializations.ryoku.fastfetchEmblem)}, unit ${builtins.toJSON (emblemUnitOf bob != null)}"
        (bob.config.myconfig.specializations.ryoku.fastfetchEmblem == null && emblemUnitOf bob == null);
    "emblem: a declared emblem generates the unit, ordered after ryoku-materialize, before ryoku-shell, wanted by ryoku-session.target, ConditionUser is the spec user" =
      yes "alice+emblem ${builtins.toJSON (emblemOk aliceEmblem (emblemUnitOf aliceEmblem))}"
        (emblemOk aliceEmblem (emblemUnitOf aliceEmblem)
          && (emblemUnitOf aliceEmblem).unitConfig.ConditionUser == "alice-ryoku");
    "emblem: the script calls import-logo and writes the sentinel only after save (real script passes)" =
      yes "alice+emblem ${builtins.toJSON (emblemScriptOk (emblemUnitOf aliceEmblem))}"
        (emblemScriptOk (emblemUnitOf aliceEmblem));
    "mutant: a script without the sentinel write, or with it before save, fails the script probe (detected)" =
      yes "a mutant still passes: ${builtins.toJSON [ (emblemScriptOk (emblemUnitOf aliceNoSentinel)) (emblemScriptOk (emblemUnitOf aliceSentinelFirst)) ]}"
        (!(emblemScriptOk (emblemUnitOf aliceNoSentinel)) && !(emblemScriptOk (emblemUnitOf aliceSentinelFirst)));
    "settings: the script has one hash-keyed seed call per declared store, seed-once sentinels, no bare tool, flock only for desktop" =
      let
        t = execText aliceA;
        stores = storesOf aliceA;
      in
      yes "stores ${toString stores}, hashes ${builtins.toJSON (map (hashOf aliceA) stores)}, bare ${builtins.toJSON (probes.bareToolLines t)}"
        (lib.all (st: hashOf aliceA st != null) stores && lib.length stores == 3
          && lib.hasInfix "settings-seeded-$store-$hash" t && lib.hasInfix "mode=seed-once" t && probes.bareToolLines t == [ ]
          && lib.hasInfix "bin/flock -x 9" t && !(lib.hasInfix "flock" (builtins.replaceStrings [ "desktop" ] [ "" ] (lib.concatStringsSep "\n" (lib.filter (l: lib.hasPrefix "seed shell" l || lib.hasPrefix "seed theme" l) (lib.splitString "\n" t))))));
    "settings: changing a value changes only that store's sentinel hash; enforce mode drops the sentinel gate" =
      yes "theme ${builtins.toJSON [ (hashOf aliceA "theme") (hashOf aliceB "theme") ]}, shell ${builtins.toJSON [ (hashOf aliceA "shell") (hashOf aliceB "shell") ]}"
        (hashOf aliceA "theme" != hashOf aliceB "theme" && hashOf aliceA "shell" == hashOf aliceB "shell" && hashOf aliceA "desktop" == hashOf aliceB "desktop"
          && lib.hasInfix "mode=enforce" (execText aliceE) && lib.hasInfix "mode=seed-once" (execText aliceA));
    "settings: valid settings raise no settings assertion (control for the next checks)" =
      eq "failing" (failingSet aliceOkSet) [ ];
    "settings: a hub store, an i18n-llm store, an unknown store and shell.python.general.location each fail an assertion with their own message" =
      yes "failing: ${builtins.toJSON (map failingSet [ aliceHub aliceI18n aliceBogus aliceLoc ])}"
        (lib.all (h: hasMsg "must not be declared" (failingSet h)) [ aliceHub aliceI18n ]
          && hasMsg "unknown store" (failingSet aliceBogus) && !(hasMsg "must not be declared" (failingSet aliceBogus))
          && lib.length (failingSet aliceLoc) == 1 && hasMsg "python.general.location" (failingSet aliceLoc));
    "mutant: without the secret-store, unknown-store or location assertion the matching case loses its message (detected)" =
      yes "mutants still fail: ${builtins.toJSON (map failingSet [ noSecretAssert noUnknownAssert noLocAssert ])}"
        (!(hasMsg "must not be declared" (failingSet noSecretAssert)) && failingSet noUnknownAssert == [ ] && failingSet noLocAssert == [ ]);

    "input: kbLayout and kbVariant are the first entry of the constants lists, kbOptions is empty even with keyboardOptions set, naturalScroll false" =
      eq "input" (inputOf kbTwin) { kbLayout = "de"; kbVariant = "nodeadkeys"; kbOptions = ""; naturalScroll = false; };
    "input: an empty keyboardVariant gives an empty kbVariant" =
      eq "input" (inputOf kbEmpty) { kbLayout = "us"; kbVariant = ""; kbOptions = ""; naturalScroll = false; };
    "input: a leaf override (kbLayout, naturalScroll) wins and the other keys stay" =
      eq "input" (inputOf kbOverride) { kbLayout = "fr"; kbVariant = "nodeadkeys"; kbOptions = ""; naturalScroll = true; };
    "mutant: taking the whole layout string instead of the first entry is detected" =
      yes "mutant kbLayout ${builtins.toJSON (inputOf wholeLayoutTwin).kbLayout}" ((inputOf wholeLayoutTwin).kbLayout == "de,us" && (inputOf kbTwin).kbLayout == "de");

    "power store: accepted as a store (no settings assertion), an unknown store is still rejected (control)" =
      yes "power ${builtins.toJSON (failingSet alicePower)}, bogus ${builtins.toJSON (failingSet aliceBogus)}" (failingSet alicePower == [ ] && hasMsg "unknown store" (failingSet aliceBogus));
    "mutant: without power in the allowed stores a power declaration fails the unknown-store assertion (detected)" =
      yes "mutant ${builtins.toJSON (failingSet noPowerStore)}" (hasMsg "unknown store" (failingSet noPowerStore) && failingSet alicePower == [ ]);
    "power: with the layer idle dim, lock and screen off equal the hypridle options (defaults and changed values), suspend 900 on battery and 1800 on AC, onDesktops true" =
      yes "default ${builtins.toJSON (idleOf bob)}, changed ${builtins.toJSON (idleOf bobHy)}"
        (map (a: stageTimes (idleOf bob).${a}) [ "battery" "ac" ] == lib.replicate 2 { dimSec = 300; lockSec = 330; screenOffSec = 360; }
          && map (a: stageTimes (idleOf bobHy).${a}) [ "battery" "ac" ] == lib.replicate 2 { dimSec = 111; lockSec = 222; screenOffSec = 333; }
          && [ (idleOf bob).battery.suspendSec (idleOf bob).ac.suspendSec (idleOf bobHy).battery.suspendSec ] == [ 900 1800 900 ]
          && (idleOf bob).onDesktops && (idleOf bob).enabled);
    "power: a host value for suspendSec (0) beats the layer default; the profile, power-saver and auto switch come from the layer; alice (no layer) has no power store" =
      yes "override ${builtins.toJSON [ (idleOf bobNoSusp).battery.suspendSec (idleOf bobNoSusp).ac.suspendSec ]}"
        ([ (idleOf bobNoSusp).battery.suspendSec (idleOf bobNoSusp).ac.suspendSec ] == [ 0 0 ]
          && (settingsOf bob).power-profile.profile == "performance" && (settingsOf bob).performance.autoPowerSaverOnBattery
          && (settingsOf bob).power.profiles.power-saver == { governor = "powersave"; epp = "balance_power"; maxFreqPct = 90; }
          && !((settingsOf alice) ? power));
    "mutant: a hard-coded dimSec stays at 300 when the hypridle option changes (detected)" =
      yes "mutant dimSec ${toString (idleOf hardIdle).battery.dimSec}" ((idleOf hardIdle).battery.dimSec == 300 && (idleOf bobHy).battery.dimSec == 111);
    "mutant: without mkDefault on suspendSec the host override of 0 conflicts and evaluation fails (detected), the real layer evaluates (control)" =
      yes "mutant evaluates ${builtins.toJSON (builtins.tryEval (builtins.deepSeq (idleOf noSuspDefault) true)).success}"
        (!(builtins.tryEval (builtins.deepSeq (idleOf noSuspDefault) true)).success && (builtins.tryEval (builtins.deepSeq (idleOf bobNoSusp) true)).success);

    "matugen: with the layer the matugen store follows constants.theme.polarity (dark: dark, light: light) with expressive scheme, darkness, contrast 0" =
      yes "dark ${builtins.toJSON (matugenOf bob)}, light ${builtins.toJSON (matugenOf bobLight)}"
        (matugenOf bob == { mode = "dark"; schemeType = "scheme-expressive"; prefer = "darkness"; contrast = 0; }
          && matugenOf bobLight == { mode = "light"; schemeType = "scheme-expressive"; prefer = "darkness"; contrast = 0; });
    "matugen: with light polarity shell.theme.matugen.mode is Light and ryogami.matugen.mode light; with dark Dark and dark" =
      yes "light ${builtins.toJSON [ (settingsOf bobLight).shell.theme.matugen.mode (settingsOf bobLight).ryogami.matugen.mode ]}, dark ${builtins.toJSON [ (settingsOf bob).shell.theme.matugen.mode (settingsOf bob).ryogami.matugen.mode ]}"
        ((settingsOf bobLight).shell.theme.matugen.mode == "Light" && (settingsOf bobLight).ryogami.matugen.mode == "light"
          && (settingsOf bob).shell.theme.matugen.mode == "Dark" && (settingsOf bob).ryogami.matugen.mode == "dark");
    "mutant: a hard-coded dark matugen mode stays dark under light polarity (detected)" =
      yes "mutant mode ${builtins.toJSON (matugenOf hardDark).mode}" ((matugenOf hardDark).mode == "dark" && (matugenOf bobLight).mode == "light");

    "theme assertion: the table theme Dracula with dark polarity passes, with light polarity fails naming the table, an unknown theme with light polarity passes" =
      yes "dark ${builtins.toJSON (failingSet bob)}, light ${builtins.toJSON (failingSet bobLight)}, unknown ${builtins.toJSON (failingSet bobLightOther)}"
        (failingSet bob == [ ] && lib.length (failingSet bobLight) == 1 && hasMsg "Dracula" (failingSet bobLight) && hasMsg "known polarities" (failingSet bobLight)
          && failingSet bobLightOther == [ ]);
    "mutant: without the polarity assertion Dracula with light polarity passes (detected)" =
      yes "mutant still fails: ${builtins.toJSON (failingSet noPolarityAssert)}" (failingSet noPolarityAssert == [ ]);

    "home: myconfig.specializations.ryoku.user and .home are the spec user's account and home (alice: /home/alice-ryoku, bob: /home/bob-ryoku)" =
      eq "user/home"
        [ bob.config.myconfig.specializations.ryoku.user bob.config.myconfig.specializations.ryoku.home (usersOf (spec bob)).${ryokuUser bob}.home alice.config.myconfig.specializations.ryoku.home ]
        [ "bob-ryoku" "/home/bob-ryoku" "/home/bob-ryoku" "/home/alice-ryoku" ];
    "launcher: heroImage is file:// plus the spec user's home plus the wallpaper path, so another base user gives another path without the layer's name" =
      yes "bob ${heroOf bob}, alice ${heroOf aliceLayer}"
        (heroOf bob == "file://${(usersOf (spec bob)).${ryokuUser bob}.home}/Pictures/Wallpapers/wallhaven-vpyrm5.jpg"
          && heroOf aliceLayer == "file:///home/alice-ryoku/Pictures/Wallpapers/wallhaven-vpyrm5.jpg"
          && !(lib.hasInfix "bob" (heroOf aliceLayer)) && !(lib.hasInfix "krit" (heroOf aliceLayer)));
    "theme store: theme.scheme is not declared (settings.theme absent or without scheme)" =
      yes "theme ${builtins.toJSON ((settingsOf bob).theme or { })}" (!((settingsOf bob).theme or { } ? scheme));

    "apps: browser/terminal/editor/files/notes derive from the constants (terminal editor and file manager are wrapped in the terminal)" =
      eq "apps" (appsOf appsTerm) (expectApps appsTerm);
    "apps: terminal editor nvim gives editor == notes == '<term> -e nvim' and files '<term> -e yazi'" =
      eq "apps" (appsOf appsTerm) { browser = "fox"; terminal = "kitty"; editor = "kitty -e nvim"; files = "kitty -e yazi"; notes = "kitty -e nvim"; };
    "apps: a GUI editor and file manager stay bare, notes equals the editor" =
      eq "apps" (appsOf appsGui) { browser = "fox"; terminal = "kitty"; editor = "code"; files = "dolphin"; notes = "code"; };
    "apps: a non-kitty terminal (foot) is used for the terminal and for the -e wrapping" =
      eq "apps" (appsOf appsFoot) { browser = "fox"; terminal = "foot"; editor = "foot -e nvim"; files = "foot -e yazi"; notes = "foot -e nvim"; };
    "apps: overriding one key wins over the default and the other keys stay" =
      eq "apps" (appsOf appsOverride) { browser = "mine"; terminal = "kitty"; editor = "kitty -e nvim"; files = "kitty -e yazi"; notes = "kitty -e nvim"; };
    "apps: programs.ryoku.browser stays null in the spec" = eq "browser" (spec bob).programs.ryoku.browser null;
    "mutant: hardcoding kitty in the module fails the foot control (detected)" =
      yes "mutant apps ${builtins.toJSON (appsOf hardKittyFoot)} equal the foot expectation" (appsOf hardKittyFoot != appsOf appsFoot);

    "binds: the spec user gets hypr/user.lua and niri/user.kdl with force = true, no mango/user.conf; the base user gets none" =
      yes "force ${builtins.toJSON (map (n: (hmF bob).${n}.force) bindFiles)}, mango file ${builtins.toJSON ((hmF bob) ? "mango/user.conf")}"
        (lib.all (n: (hmF bob) ? ${n} && (hmF bob).${n}.force == true && !(bob.config.home-manager.users.bob.xdg.configFile ? ${n})) bindFiles && !((hmF bob) ? "mango/user.conf"));
    "binds: no vicinae, swayosd, swaync, waybar or grimblast in any rendered file; the legacy-profile mutant leaks vicinae (detected)" =
      yes "hits ${builtins.toJSON (map probes.legacyHits [ bobT.hypr bobT.niri ])}, mutant ${builtins.toJSON (probes.legacyHits (binT legacyBinds).hypr)}"
        (lib.all (t: probes.legacyHits t == [ ]) [ bobT.hypr bobT.niri ] && probes.legacyHits (binT legacyBinds).hypr != [ ]);
    "binds: no duplicate chord per file; a repeated host extra bind is flagged (control)" =
      yes "bob ${builtins.toJSON [ (probes.dups (probes.luaBindChords bobT.hypr)) (probes.dups (probes.niriChords bobT.niri)) ]}, dup twin ${builtins.toJSON (probes.dups (probes.luaBindChords bobDupT.hypr))}"
        (probes.luaBindChords bobT.hypr != [ ] && probes.niriChords bobT.niri != [ ]
          && probes.dups (probes.luaBindChords bobT.hypr) == [ ] && probes.dups (probes.niriChords bobT.niri) == [ ]
          && probes.dups (probes.luaBindChords bobDupT.hypr) != [ ]);
    "binds: hyprland unbind/bind pairing holds" =
      yes "pairing ${builtins.toJSON (probes.luaPairingOk bobT.hypr)}" (probes.luaPairingOk bobT.hypr);
    "binds: host extra binds (hyprland, niri) reach their files and are absent without them (control)" =
      yes "extra hit ${builtins.toJSON [ (lib.hasInfix "SUPER + F12" bobExtraT.hypr) (lib.hasInfix "Super+F12" bobExtraT.niri) ]}"
        (lib.hasInfix "SUPER + F12" bobExtraT.hypr && lib.hasInfix "Super+F12" bobExtraT.niri
          && !(lib.hasInfix "F12" bobT.hypr) && !(lib.hasInfix "F12" bobT.niri));
    "mutant: without force = true on hypr/user.lua the force probe fails (detected)" =
      yes "mutant still forces" ((hmF noForceBinds)."hypr/user.lua".force == false);
    "binds lib: hyprland yields 98 binds with the recorded anchor chords for a fixed profile; a null launcher changes the count (control)" =
      yes "count ${toString (lib.length (hyprLib libShell))}, null launcher ${toString (lib.length (hyprLib (libShell // { launcher = null; })))}"
        (lib.length (hyprLib libShell) == 98 && lib.length (hyprLib (libShell // { launcher = null; })) == 97
          && lib.all (a: lib.elem a hyprChords) [ "SUPER+SHIFT + C" "SUPER + return" "SUPER + F" "SUPER + B" "SUPER + C" ]);
    "binds lib: niri yields 78 binds including Mod+Alt+H, Caps_Lock and Mod+1 for a fixed profile" =
      yes "count ${toString (lib.length (lib.attrNames niriLib))}"
        (lib.length (lib.attrNames niriLib) == 78 && lib.all (k: niriLib ? ${k}) [ "Mod+Alt+H" "Caps_Lock" "Mod+1" ]);
    "binds lib: mango yields 99 bind, 14 bindl, 2 bindsl, 2 mousebind, 2 axisbind, 8 gesturebind lines with the recorded anchors for a fixed profile" =
      yes "counts ${builtins.toJSON (lib.mapAttrs (_: builtins.length) mangoLib)}"
        (lib.mapAttrs (_: builtins.length) mangoLib == { bind = 99; bindl = 14; bindsl = 2; mousebind = 2; axisbind = 2; gesturebind = 8; }
          && lib.all (l: lib.elem l mangoLib.bind) [ "SUPER,Return,spawn,term" "SUPER,F,spawn,term --class fm -e fm" ]);

    "personal: kitty.conf and config.fish and yazi.toml are forced off, user.conf and user.fish exist" =
      yes "enables ${builtins.toJSON [ (hmF bob)."kitty/kitty.conf".enable (hmF bob)."fish/config.fish".enable (hmF bob)."yazi/yazi.toml".enable (hmF bob)."kitty/user.conf".enable (hmF bob)."fish/user.fish".enable ]}, base ${builtins.toJSON [ bob.config.home-manager.users.bob.xdg.configFile."kitty/kitty.conf".enable bob.config.home-manager.users.bob.xdg.configFile."fish/config.fish".enable ]}"
        (!(hmF bob)."kitty/kitty.conf".enable && !(hmF bob)."fish/config.fish".enable && !(hmF bob)."yazi/yazi.toml".enable
          && (hmF bob)."kitty/user.conf".enable && (hmF bob)."fish/user.fish".enable
          && bob.config.home-manager.users.bob.xdg.configFile."kitty/kitty.conf".enable && bob.config.home-manager.users.bob.xdg.configFile."fish/config.fish".enable);
    "personal: user.fish lacks the HM single-source guard line (the base config.fish has it) and keeps the eza aliases" =
      let baseFish = builtins.readFile bob.config.home-manager.users.bob.xdg.configFile."fish/config.fish".source; in
      yes "guard in user.fish ${builtins.toJSON (lib.hasInfix guard (userFish bob))}, in base ${builtins.toJSON (lib.hasInfix guard baseFish)}"
        (!(lib.hasInfix guard (userFish bob)) && lib.hasInfix guard baseFish && lib.hasInfix "alias ls eza" (userFish bob) && lib.hasInfix "alias ll 'eza -l'" (userFish bob));
    "mutant: without the guard-stripping sed user.fish keeps the guard line (detected)" =
      yes "mutant still strips it" (lib.hasInfix guard (userFish noFishSed));
    "personal: YAZI_CONFIG_HOME is set to the yazi-user link farm in home.sessionVariables and environment.sessionVariables, the farm holds yazi.toml, the base sets neither" =
      yes "vars ${builtins.toJSON [ ((hmCfg bob).home.sessionVariables.YAZI_CONFIG_HOME or null) ((spec bob).environment.sessionVariables.YAZI_CONFIG_HOME or null) ]}"
        ((hmCfg bob).home.sessionVariables.YAZI_CONFIG_HOME == yaziWant bob && (spec bob).environment.sessionVariables.YAZI_CONFIG_HOME == yaziWant bob
          && (builtins.readDir (hmF bob)."yazi-user".source) ? "yazi.toml"
          && !(bob.config.environment.sessionVariables ? YAZI_CONFIG_HOME) && !(bob.config.home-manager.users.bob.home.sessionVariables ? YAZI_CONFIG_HOME));
    "mutant: without the home.sessionVariables entry the yazi variable probe fails (detected)" =
      yes "mutant still sets it" ((hmCfg noYaziVar).home.sessionVariables.YAZI_CONFIG_HOME or null != yaziWant noYaziVar);
    "personal: home-manager.backupFileExtension is set in the spec" =
      yes "none" ((spec bob).home-manager.backupFileExtension or null != null);

    "audit: programs.dconf and services.fwupd are on in the spec (fwupd is off in the base, control)" =
      eq "dconf, fwupd (spec), fwupd (base)" [ (spec bob).programs.dconf.enable (spec bob).services.fwupd.enable bob.config.services.fwupd.enable ] [ true true false ];

    "stylix-lite: stylix is on with autoEnable false at the NixOS and home-manager level, on a base where autoEnable is true" =
      eq "enable/autoEnable (spec nixos, spec hm, base nixos)" [ (spec bob).stylix.enable (spec bob).stylix.autoEnable (hmCfg bob).stylix.autoEnable bob.config.stylix.autoEnable ] [ true false false true ];
    "stylix-lite: the home-manager targets on are exactly the non-clashing set and the clashing ones are off" =
      yes "on ${toString (hmTargetsOn bob)}, clashing on: ${toString (lib.filter (n: (hmCfg bob).stylix.targets.${n}.enable) stylixOff)}"
        (hmTargetsOn bob == lib.sort (a: b: a < b) stylixOn && lib.all (n: !(hmCfg bob).stylix.targets.${n}.enable) stylixOff);
    "stylix-lite: the repo-level targets mirror the on and off lists" =
      eq "myconfig.stylix.targets"
        (lib.mapAttrs (_: t: t.enable) (lib.getAttrs (stylixOn ++ [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" ]) (spec bob).myconfig.stylix.targets))
        (lib.genAttrs stylixOn (_: true) // lib.genAttrs [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" ] (_: false));
    "stylix-lite: the colour scheme equals the base's at both levels" =
      eq "scheme" [ (spec bob).stylix.base16Scheme (hmCfg bob).stylix.base16Scheme ] [ bob.config.stylix.base16Scheme bob.config.home-manager.users.bob.stylix.base16Scheme ];
    "mutant: without gtk in the off list the gtk target turns on (detected)" =
      yes "mutant gtk target still off" (hmCfg noGtkOff).stylix.targets.gtk.enable;
    "stylix-lite: catppuccin.eza follows the base theme: on for the catppuccin base, off for the other; the constant is false in both specs" =
      eq "eza (bob, alice), constants"
        [ (hmCfg bob).catppuccin.eza.enable (hmCfg alice).catppuccin.eza.enable (spec bob).myconfig.constants.theme.catppuccin (spec alice).myconfig.constants.theme.catppuccin ]
        [ true false false false ];
    "mutant: with catppuccin.eza forced false the catppuccin base is detected" =
      yes "mutant still on" (!(hmCfg noEza).catppuccin.eza.enable);

    "source: the generic module names no user layer (option namespace, quoted name, hyphenated name)" =
      yes "generic module mentions a layer of ${toString layerNames}" (layerNames != [ ] && !(mentionsLayer genericText));
    "control: the layer probe fires on the user layer module" =
      yes "the probe does not match the layer module" (mentionsLayer layerText);
    "source: the layer lives under users/<layer>/ (guards the probe's layer list)" =
      yes "layer module is not under users/" (lib.any (l: lib.hasInfix "/users/${l}/" (toString layerFile)) layerNames);
  };

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
  privateSyncScript = let p = toString (lib.head (lib.toList (privSvc (spec bob)).Service.ExecStart)); in builtins.seq (builtins.readFile p) p;
  fastfetchWrapper = let n = lib.filter (p: lib.getName p == "ryoku-fastfetch") (hmCfg bob).home.packages; p = "${lib.head n}/bin/ryoku-fastfetch"; in builtins.seq (builtins.readFile p) p;
  seedScripts = { a = realised aliceA; b = realised aliceB; enforce = realised aliceE; };
}
