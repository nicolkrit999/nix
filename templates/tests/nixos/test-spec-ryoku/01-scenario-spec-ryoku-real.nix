{ host }:
let
  probes = import ./fixture/probes.nix { inherit lib; };
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  root = builtins.unsafeDiscardStringContext flake.outPath;

  sys = flake.nixosConfigurations.${host};
  base = sys.config;
  spec = base.specialisation.ryoku.configuration;
  hasSchool = base.specialisation ? school;
  school = base.specialisation.school.configuration;

  baseUser = base.myconfig.constants.user;
  ryokuUser = spec.myconfig.constants.user;
  schoolUser = school.myconfig.constants.user;
  baseHome = base.users.users.${baseUser}.home;
  home = spec.users.users.${ryokuUser}.home;
  ryokuU = spec.users.users.${ryokuUser};
  baseU = base.users.users.${baseUser};

  genericText = builtins.readFile "${root}/modules/nixos/specializations/ryoku.nix";
  layerNames = lib.attrNames (lib.filterAttrs (_: t: t == "directory") (builtins.readDir "${root}/users"));
  layerFiles = lib.filter builtins.pathExists (map (l: "${root}/users/${l}/nixos/specializations/ryoku.nix") layerNames);
  layerText = lib.concatMapStrings builtins.readFile layerFiles;

  eq = what: actual: expected:
    if actual == expected then "ok"
    else "FAIL: ${what}: expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";
  yes = what: cond: if cond then "ok" else "FAIL: ${what}";
  showPath = lib.concatStringsSep ".";

  rangeOf = u: kind: map (r: { start = r.startUid or r.startGid; inherit (r) count; }) (u.${kind} or [ ]);
  overlaps = a: b: lib.any (x: lib.any (y: x.start < y.start + y.count && y.start < x.start + x.count) b) a;
  rangesClear = kind: others:
    let mine = rangeOf ryokuU kind; in
    mine != [ ] && lib.all (o: rangeOf o kind != [ ] && !(overlaps mine (rangeOf o kind))) others;
  others = [ baseU ] ++ lib.optional hasSchool school.users.users.${schoolUser};

  claims = u: attrs: lib.filterAttrs (_: v: (v.owner or null) == u || lib.hasPrefix "/home/${u}/" (v.path or "")) attrs;
  mentionsUser = u: l: lib.hasInfix " ${u} " l || lib.hasInfix "/home/${u}/" l;

  offPaths =
    map (n: [ "programs" n ]) [ "cosmic" "gnome" "hyprland" "kde" "mango" "niri" "caelestia" "noctalia" "skwdWall" "vicinae" "walker" "swayosd" "waybar-hyprland" "waybar-mango" "waybar-niri" "fastfetch" "starship" ]
    ++ map (n: [ "services" n ]) [ "auto-cpufreq" "coffee" "hypridle" "sddm-astronaut" "sddm-pixie" "swaync" "tlp" ]
    ++ [ [ "qt" ] [ "bluetooth" ] ];
  declared = p: lib.hasAttrByPath ([ "myconfig" ] ++ p ++ [ "enable" ]) sys.options;
  optOf = c: p: lib.attrByPath ([ "myconfig" ] ++ p ++ [ "enable" ]) null c;
  offChecks = lib.listToAttrs (map
    (p: lib.nameValuePair "ryoku: myconfig.${showPath p}.enable is declared and false in the spec"
      (if !(declared p) then "FAIL: option myconfig.${showPath p}.enable does not exist on this host (renamed or removed: the spec's mkOff silently skips it)"
      else eq "myconfig.${showPath p}.enable" (optOf spec p) false))
    offPaths);

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
  borgDeclared = lib.filter declared borgPaths;
  borgOn = lib.filter (p: optOf spec p != false) borgDeclared;
  reenableBaseOn = lib.filter (p: declared p && optOf base p == true) reenablePaths;
  reenableLost = lib.filter (p: optOf spec p != true) reenableBaseOn;

  sessions = c: lib.concatMap (p: p.providedSessions or [ ]) c.services.displayManager.sessionPackages;
  ryokuSessions = [ "ryoku-hyprland" "ryoku-niri" "ryoku-mango" ];
  keptSessions = [ "ryoku-hyprland" "ryoku-niri" ];
  sessionPkgs = c: c.services.displayManager.sessionPackages;
  mangoPkgs = c: lib.filter (p: lib.elem "ryoku-mango" p.providedSessions) (sessionPkgs c);
  otherPkgs = c: lib.filter (p: !(lib.elem "ryoku-mango" p.providedSessions)) (sessionPkgs c);
  linked = c: p: lib.hasInfix (builtins.unsafeDiscardStringContext (toString p)) (builtins.unsafeDiscardStringContext c.services.displayManager.sessionData.desktops.buildCommand);
  persist = c: map (d: d.directory) c.environment.persistence."/persist".directories;
  tmp = spec.systemd.tmpfiles.rules;
  homeRules = lib.filter (r: lib.hasPrefix "d ${home} " r) tmp;
  hm = spec.home-manager.users.${ryokuUser};
  baseHm = base.home-manager.users.${baseUser};
  syncUnits = lib.attrNames probes.repoSyncUnits;
  unitText = n: builtins.unsafeDiscardStringContext (builtins.readFile (lib.head (lib.toList hm.systemd.user.services.${n}.Service.ExecStart)));
  syncBad = mut: lib.filterAttrs (n: u: probes.repoSyncProblems u (mut (unitText n)) == [ ]) probes.repoSyncUnits;

  hmF = hm.xdg.configFile;
  baseHmF = baseHm.xdg.configFile;
  sddmSeed = spec.systemd.services.ryoku-sddm-theme-seed or null;
  impOn = spec.myconfig.services.impermanence.enable;
  sddmOn = spec.services.displayManager.sddm.enable;

  declaredStores = lib.attrNames (lib.filterAttrs (_: v: v != { }) base.myconfig.specializations.ryoku.settings);
  seedUnit = spec.systemd.user.services.ryoku-settings-seed or null;
  seedText = builtins.readFile seedUnit.serviceConfig.ExecStart;
  seedLines = lib.splitString "\n" seedText;
  emblemUnit = spec.systemd.user.services.ryoku-fastfetch-emblem-seed or null;
  emblemValue = base.myconfig.specializations.ryoku.fastfetchEmblem;
  failingSettings = lib.filter (m: lib.hasPrefix "specializations.ryoku.settings" m) (map (a: a.message) (lib.filter (a: !a.assertion) base.assertions));
  storeLine = st: l: builtins.match ".*seed ${st} /nix/store/[^ ]+-ryoku-settings-${st}\\.json [0-9a-f]{16}[ ;].*" l != null;

  bindFiles = [ "hypr/user.lua" "niri/user.kdl" ];
  hyprT = hmF."hypr/user.lua".text;
  niriT = hmF."niri/user.kdl".text;
  hyprBase = lib.attrByPath [ "wayland" "windowManager" "hyprland" "settings" "bind" ] [ ] baseHm;
  hyprBaseChords = map (b: builtins.head b._args) hyprBase;
  hyprAnchors = [ "SUPER+SHIFT + C" "SUPER + return" "SUPER + F" "SUPER + B" "SUPER + C" ];

  peers = lib.filter (n: n != spec.myconfig.constants.hostname) (lib.attrNames (lib.filterAttrs
    (_: h: h.nixos != { } && (h.myconfig.krit.system.ssh-config.enable or false) == true)
    spec.myconfig.hosts));
  peerUserOf = p: spec.myconfig.hosts.${p}.myconfig.constants.user;
  sshExtra = spec.programs.ssh.extraConfig;
  sopsAlias = hm.home.shellAliases.sops-common or "";
  aliasMatch = builtins.match "cd [^ ]*/users/([^/ ]+)/common/sops && sops ([^ ]+)" sopsAlias;
  secretSops = n: spec.sops.secrets.${n}.sopsFile;

  stylixOn = [ "bat" "blender" "cava" "fzf" "gdu" "gedit" "lazygit" "nixcord" "tmux" "zathura" "zen-browser" ];
  stylixOff = [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" "fontconfig" "font-packages" "nixos-icons" ];
  hmTargetsOn = lib.sort (a: b: a < b) (lib.attrNames (lib.filterAttrs (n: _: hm.stylix.targets.${n}.enable or false == true) hm.stylix.targets));

  appsCfg = base.myconfig.specializations.ryoku.settings.desktop.desktop.apps or { };
  bc = base.myconfig.constants;
  declared_ = base.myconfig.specializations.ryoku.settings;
  inputCfg = declared_.desktop.desktop.input;
  matugenCfg = declared_.matugen;
  firstOf = str: lib.head (lib.splitString "," str);
  inTerm = app: if lib.elem app bc.terminalApps then "${bc.terminal.name} -e ${app}" else app;

  sddmSet = c: c.services.displayManager.sddm.settings;
  cursorTheme = c: lib.attrByPath [ "Theme" "CursorTheme" ] null (sddmSet c);
  greeterEnv = c: lib.splitString "," (lib.attrByPath [ "General" "GreeterEnvironment" ] "" (sddmSet c));
  xcursorEntry = "XCURSOR_PATH=/run/current-system/sw/share/icons";
  cursorPkg = base.myconfig.specializations.ryoku.sddmCursorPackage;

  kbdInBase = base.systemd.user.services ? kbd-backlight-relight && base.systemd.user.services.kbd-backlight-relight.enable;
  jetInBase = baseHm.systemd.user.services ? hyprland-jetkvm-teardown;
  hostUnits = kbdInBase || jetInBase;

  checks = {
    "ryoku: the specialisation exists, is tagged ryoku, programs.ryoku is on in it and off in the base" =
      yes "tags ${builtins.toJSON spec.system.nixos.tags}, spec ${builtins.toJSON spec.programs.ryoku.enable}, base ${builtins.toJSON base.programs.ryoku.enable}"
        (lib.elem "ryoku" spec.system.nixos.tags && spec.programs.ryoku.enable && !base.programs.ryoku.enable);
    "ryoku: constants.user is <base user>-ryoku and differs from the base user" =
      yes "user ${ryokuUser} for base ${baseUser}" (ryokuUser == "${baseUser}-ryoku" && ryokuUser != baseUser);
    "ryoku: uid is an integer, differs from the base user and from the school user" =
      yes "uids ${builtins.toJSON [ ryokuU.uid baseU.uid (if hasSchool then school.users.users.${schoolUser}.uid else null) ]}"
        (builtins.isInt ryokuU.uid && ryokuU.uid != baseU.uid && (!hasSchool || ryokuU.uid != school.users.users.${schoolUser}.uid));
    "ryoku: subuid and subgid ranges are set and overlap neither the base user nor the school user" =
      yes "ranges ${builtins.toJSON (rangeOf ryokuU "subUidRanges")} vs ${builtins.toJSON (map (u: rangeOf u "subUidRanges") others)}"
        (rangesClear "subUidRanges" others && rangesClear "subGidRanges" others);
    "control: the range overlap probe flags overlap and accepts disjoint ranges" =
      yes "overlap probe is wrong" (overlaps [{ start = 100; count = 50; }] [{ start = 120; count = 10; }] && !(overlaps [{ start = 100; count = 50; }] [{ start = 150; count = 10; }]));
    "ryoku: users.users has no base user in the spec (control: the base has it and not the ryoku user)" =
      yes "spec has base user ${builtins.toJSON (spec.users.users ? ${baseUser})}, base has ryoku user ${builtins.toJSON (base.users.users ? ${ryokuUser})}"
        (!(spec.users.users ? ${baseUser}) && base.users.users ? ${baseUser} && !(base.users.users ? ${ryokuUser}));
    "ryoku: home-manager.users is exactly the ryoku user in the spec and the base user in the base" =
      eq "hm users" [ (lib.attrNames spec.home-manager.users) (lib.attrNames base.home-manager.users) ] [ [ ryokuUser ] [ baseUser ] ];
    "ryoku: no sops secret or template in the spec is owned by or placed under the base user" =
      yes "base user owns ${toString (lib.attrNames (claims baseUser spec.sops.secrets // claims baseUser spec.sops.templates))}"
        (claims baseUser spec.sops.secrets == { } && claims baseUser spec.sops.templates == { });
    "control: the base has secrets owned by the base user and the claim probe flags synthetic owners and paths" =
      yes "base has no such secret or the probe is wrong"
        (claims baseUser base.sops.secrets != { }
          && claims baseUser { x = { owner = baseUser; }; y = { path = "/home/${baseUser}/.ssh/k"; }; z = { owner = "root"; path = "/run/z"; }; } == { x = { owner = baseUser; }; y = { path = "/home/${baseUser}/.ssh/k"; }; });
    "ryoku: no tmpfiles rule or fileSystem in the spec names the base user's home" =
      yes "a rule or mount still names ${baseHome}"
        (!(lib.any (mentionsUser baseUser) tmp) && !(lib.any (lib.hasPrefix "${baseHome}/") (lib.attrNames spec.fileSystems)));
    "control: the home probe flags a rule and a mount of the base user" =
      yes "probe is wrong" (mentionsUser baseUser "d /home/${baseUser}/x 0700 ${baseUser} users -" && !(mentionsUser baseUser "d /home/${ryokuUser}/x 0700 ${ryokuUser} users -"));
    "ryoku: exactly one tmpfiles rule creates the ryoku home /home/<user>, owned by the ryoku user with the account's homeMode" =
      yes "home ${home}, rules ${builtins.toJSON homeRules}"
        (home == "/home/${ryokuUser}" && lib.length homeRules == 1 && lib.hasPrefix "d ${home} ${ryokuU.homeMode} ${ryokuUser} " (lib.head homeRules));
    "ryoku: /home is a real filesystem needed for boot and the ryoku home is under it" =
      yes "fs ${builtins.toJSON (spec.fileSystems."/home".fsType or null)}"
        (spec.fileSystems."/home".fsType != "tmpfs" && spec.fileSystems."/home".neededForBoot && lib.hasPrefix "/home/" home);

    "source: the generic module has no occurrence of the base user's name" =
      yes "modules/nixos/specializations/ryoku.nix mentions ${baseUser}" (!(lib.hasInfix baseUser genericText));
    "control: the user-layer module does mention the base user's name (the probe bites)" =
      yes "the probe does not match the layer module" (layerFiles != [ ] && lib.hasInfix baseUser layerText);

    "ryoku: constants.theme.catppuccin is false in the spec" =
      eq "catppuccin" spec.myconfig.constants.theme.catppuccin false;
    "ryoku: constants.shell, programs.ryoku.shell and the default user shell agree" =
      let shells = [ spec.myconfig.constants.shell spec.programs.ryoku.shell spec.users.defaultUserShell.pname ]; in
      yes "shells ${builtins.toJSON shells}" (lib.length (lib.unique shells) == 1);
    "ryoku: the borg backup modules are false in the spec (the spec has no own borg repo)" =
      yes "still on: ${toString (map showPath borgOn)}" (borgDeclared != [ ] && borgOn == [ ]);
    "ryoku: every personal module the base has on (ssh config, clouds, NAS mounts, home base, private dotfiles) is on in the spec too" =
      yes "off in the spec: ${toString (map showPath reenableLost)}" (reenableBaseOn != [ ] && reenableLost == [ ]);
    "ryoku: programs.ryoku.updateFlake is not the default, not under a home and not the flake checkout" =
      yes "updateFlake ${spec.programs.ryoku.updateFlake}, default ${builtins.toJSON sys.options.programs.ryoku.updateFlake.default}"
        (spec.programs.ryoku.updateFlake != sys.options.programs.ryoku.updateFlake.default
          && !(lib.hasPrefix "/home/" spec.programs.ryoku.updateFlake)
          && !(lib.hasInfix spec.myconfig.constants.flakeDir spec.programs.ryoku.updateFlake));
    "ryoku: defaultCompositor is hyprland" = eq "defaultCompositor" spec.programs.ryoku.defaultCompositor "hyprland";

    "ryoku: pipewire, gnome-keyring, polkit, NetworkManager, power-profiles-daemon and gpu-screen-recorder are on" =
      let
        probes = {
          pipewire = spec.services.pipewire.enable;
          gnome-keyring = spec.services.gnome.gnome-keyring.enable;
          polkit = spec.security.polkit.enable;
          networkmanager = spec.networking.networkmanager.enable;
          power-profiles-daemon = spec.services.power-profiles-daemon.enable;
          gpu-screen-recorder = spec.programs.gpu-screen-recorder.enable;
          audio-module = spec.myconfig.services.audio.enable;
        };
        off = lib.attrNames (lib.filterAttrs (_: v: v != true) probes);
      in
      yes "off in the spec: ${toString off}" (off == [ ]);
    "ryoku: sddm is enabled with theme ryoku while the base theme differs" =
      yes "spec ${builtins.toJSON [ spec.services.displayManager.sddm.enable spec.services.displayManager.sddm.theme ]}, base theme ${builtins.toJSON base.services.displayManager.sddm.theme}"
        (spec.services.displayManager.sddm.enable && spec.services.displayManager.sddm.theme == "ryoku" && base.services.displayManager.sddm.theme != "ryoku");
    "ryoku: Ryoku adds all three sessions to sessionPackages in the spec and in no other config (control for the mango filter below)" =
      yes "spec ${builtins.toJSON (sessions spec)}, base ${builtins.toJSON (sessions base)}"
        (lib.all (s: lib.elem s (sessions spec) && !(lib.elem s (sessions base))) ryokuSessions);
    "ryoku: the session data offers ryoku-hyprland and ryoku-niri, not ryoku-mango, and does not autologin into it" =
      let sd = spec.services.displayManager.sessionData; in
      yes "sessionNames ${builtins.toJSON sd.sessionNames}, autologin ${builtins.toJSON sd.autologinSession}"
        (lib.all (s: lib.elem s sd.sessionNames) keptSessions && !(lib.elem "ryoku-mango" sd.sessionNames) && sd.autologinSession != "ryoku-mango");
    "ryoku: the session desktops derivation links every other session package and the ryoku-mango one is left out (by build command, nothing built)" =
      yes "mango packages ${toString (lib.length (mangoPkgs spec))}, linked ${builtins.toJSON (map (linked spec) (mangoPkgs spec))}, others linked ${builtins.toJSON (map (linked spec) (otherPkgs spec))}"
        (mangoPkgs spec != [ ] && otherPkgs spec != [ ] && lib.all (p: !(linked spec p)) (mangoPkgs spec) && lib.all (linked spec) (otherPkgs spec));
    "ryoku: the default session is a Ryoku session" =
      yes "defaultSession ${builtins.toJSON spec.services.displayManager.defaultSession}"
        (lib.hasPrefix "ryoku-" (spec.services.displayManager.defaultSession or ""));
    "ryoku: the spec portal table equals the base table (Ryoku's own fragments do not leak in) and routes Secret to gnome-keyring once" =
      yes "xdg.portal.config differs from the base or the Secret route is not exactly gnome-keyring"
        (spec.xdg.portal.config == base.xdg.portal.config
          && lib.all (k: lib.toList (spec.xdg.portal.config.${k}."org.freedesktop.impl.portal.Secret" or [ ]) == [ "gnome-keyring" ]) (lib.attrNames spec.xdg.portal.config)
          && lib.all (k: spec.xdg.portal.config ? ${k}) [ "hyprland" "niri" "mango" ]);

    "ryoku: host units that clash with the Ryoku session are disabled or absent in the spec (kbd-backlight-relight, niri-flake-polkit, hyprland-jetkvm-teardown)" =
      let
        svc = spec.systemd.user.services;
        offOrAbsent = n: !(svc ? ${n}) || svc.${n}.enable == false;
      in
      yes "kbd ${builtins.toJSON (offOrAbsent "kbd-backlight-relight")}, polkit ${builtins.toJSON (offOrAbsent "niri-flake-polkit")}, jetkvm in spec home ${builtins.toJSON (hm.systemd.user.services ? hyprland-jetkvm-teardown)}"
        (offOrAbsent "kbd-backlight-relight" && offOrAbsent "niri-flake-polkit" && !(hm.systemd.user.services ? hyprland-jetkvm-teardown));
    "control: this host defines at least one unit the spec must disable (kbd-backlight-relight or hyprland-jetkvm-teardown)" =
      yes "neither unit is defined by this host any more: drop the matching spec override" hostUnits;
    "ryoku: /var/lib/ryoku is persisted in the spec when impermanence is on, and only there" =
      yes "impermanence ${builtins.toJSON base.myconfig.services.impermanence.enable}, spec ${builtins.toJSON (lib.elem "/var/lib/ryoku" (persist spec))}, base ${builtins.toJSON (lib.elem "/var/lib/ryoku" (persist base))}"
        (if base.myconfig.services.impermanence.enable then lib.elem "/var/lib/ryoku" (persist spec) && !(lib.elem "/var/lib/ryoku" (persist base)) else true);

    "safety: system.stateVersion and the home-manager stateVersion equal the base's in the spec" =
      eq "stateVersions" [ spec.system.stateVersion hm.home.stateVersion ] [ base.system.stateVersion baseHm.home.stateVersion ];
    "safety: the boot loader selection equals the base's in the spec" =
      let loaders = c: [ c.boot.loader.grub.enable c.boot.loader.systemd-boot.enable (c.boot.lanzaboote.enable or false) c.boot.loader.efi.canTouchEfiVariables ]; in
      eq "boot loaders" (loaders spec) (loaders base);
    "safety: root, /persist and /home mount definitions equal the base's in the spec" =
      let m = c: map (p: { inherit (c.fileSystems.${p}) fsType neededForBoot; device = c.fileSystems.${p}.device or null; }) [ "/" "/persist" "/home" ]; in
      eq "mounts" (m spec) (m base);
    "safety: the sops age key and default file equal the base's in the spec" =
      eq "sops" [ spec.sops.age.keyFile (toString spec.sops.defaultSopsFile) ] [ base.sops.age.keyFile (toString base.sops.defaultSopsFile) ];
    "safety: impermanence stays on or off exactly like the base" =
      eq "impermanence" spec.myconfig.services.impermanence.enable base.myconfig.services.impermanence.enable;

    "layer: the spec creates ~/.ssh for the ryoku user and has both clone services, which the base user lacks" =
      yes "ssh ${builtins.toJSON (lib.filter (lib.hasPrefix "d ${home}/.ssh ") tmp)}, units ${builtins.toJSON (lib.attrNames hm.systemd.user.services)}"
        (lib.length (lib.filter (lib.hasPrefix "d ${home}/.ssh ") tmp) == 1
          && lib.all (n: hm.systemd.user.services ? ${n} && !(baseHm.systemd.user.services ? ${n})) syncUnits);
    "layer: the clone services are one-shot, restart on failure, are not start-limited and install into default.target" =
      let u = n: hm.systemd.user.services.${n}; in
      yes "clone unit settings are not oneshot/on-failure/unlimited/default.target"
        (lib.all (n: (u n).Service.Type == "oneshot" && (u n).Service.Restart == "on-failure" && (u n).Unit.StartLimitIntervalSec == 0 && (u n).Install.WantedBy == [ "default.target" ]) syncUnits);
    "layer: the three repo sync scripts fast-forward only, heal shallow checkouts, never reset or discard, use the right url and transport and carry no key material" =
      yes "problems ${builtins.toJSON (lib.mapAttrs (n: u: probes.repoSyncProblems u (unitText n)) probes.repoSyncUnits)}"
        (lib.all (n: probes.repoSyncProblems probes.repoSyncUnits.${n} (unitText n) == [ ]) syncUnits);
    "layer: the three repo sync units set GIT_SSL_CAINFO" =
      yes "environment ${builtins.toJSON (map (n: hm.systemd.user.services.${n}.Service.Environment) syncUnits)}"
        (lib.all (n: lib.elem "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt" hm.systemd.user.services.${n}.Service.Environment) syncUnits);
    "control: the repo sync probe fires on reset --hard, --depth and a removed --unshallow variant of every script" =
      yes "probe silent for ${toString (lib.attrNames (syncBad (lib.replaceStrings [ "merge --quiet --ff-only" ] [ "reset --hard" ])))} / ${toString (lib.attrNames (syncBad (lib.replaceStrings [ "clone --quiet" ] [ "clone --depth 1 --quiet" ])))} / ${toString (lib.attrNames (syncBad (lib.replaceStrings [ "--unshallow" ] [ "--prune" ])))}"
        (syncBad (lib.replaceStrings [ "merge --quiet --ff-only" ] [ "reset --hard" ]) == { }
          && syncBad (lib.replaceStrings [ "clone --quiet" ] [ "clone --depth 1 --quiet" ]) == { }
          && syncBad (lib.replaceStrings [ "--unshallow" ] [ "--prune" ]) == { });
    "sddm cursor: the spec's rendered sddm settings carry Theme.CursorTheme Bibata-Modern-Ice and CursorSize 24" =
      eq "Theme" (lib.filterAttrs (n: _: lib.elem n [ "CursorTheme" "CursorSize" ]) (sddmSet spec).Theme) { CursorTheme = "Bibata-Modern-Ice"; CursorSize = 24; };
    "sddm cursor: GreeterEnvironment holds XCURSOR_PATH exactly once and layer-shell only with the kwin compositor" =
      yes "entries ${builtins.toJSON (greeterEnv spec)}, compositor ${spec.services.displayManager.sddm.wayland.compositor}"
        (lib.count (e: e == xcursorEntry) (greeterEnv spec) == 1
          && lib.elem "QT_WAYLAND_SHELL_INTEGRATION=layer-shell" (greeterEnv spec) == (spec.services.displayManager.sddm.wayland.compositor == "kwin")
          && lib.all (e: lib.hasInfix "=" e) (greeterEnv spec));
    "sddm cursor: the cursor package is in the spec's systemPackages and its name matches the theme" =
      yes "package ${builtins.toJSON (cursorPkg.name or null)}"
        (cursorPkg != null && lib.elem (toString cursorPkg) (map toString spec.environment.systemPackages)
          && lib.hasPrefix (lib.toLower (lib.head (lib.splitString "-" spec.myconfig.specializations.ryoku.sddmCursorTheme))) (lib.toLower (cursorPkg.pname or cursorPkg.name)));
    "sddm cursor: with weston the spec's compositorCommand wraps weston in env with XCURSOR_PATH/THEME/SIZE and a weston.ini; the base command has none of it" =
      let
        cmd = spec.services.displayManager.sddm.wayland.compositorCommand;
        baseCmd = base.services.displayManager.sddm.wayland.compositorCommand;
        westonOf = c: lib.filter (w: lib.hasSuffix "/bin/weston" w) (lib.splitString " " c);
      in
      if spec.services.displayManager.sddm.wayland.compositor != "weston" then "ok"
      else
        yes "spec ${cmd}, problems ${builtins.toJSON (probes.westonCursorProblems { theme = "Bibata-Modern-Ice"; size = 24; cmd = cmd; })}, base ${baseCmd}"
          (probes.westonCursorProblems { theme = "Bibata-Modern-Ice"; size = 24; cmd = cmd; } == [ ]
            && !(lib.hasInfix "XCURSOR_THEME" baseCmd)
            && (base.services.displayManager.sddm.wayland.compositor != "weston" || westonOf cmd == westonOf baseCmd));
    "control: the weston cursor probe flags a plain weston command and a wrong theme" =
      yes "probe silent"
        (probes.westonCursorProblems { theme = "Bibata-Modern-Ice"; size = 24; cmd = "/x/bin/weston --shell=kiosk -c /x/weston.ini"; } != [ ]
          && probes.westonCursorProblems { theme = "Bibata-Modern-Ice"; size = 24; cmd = "/x/bin/env XCURSOR_PATH=/run/current-system/sw/share/icons XCURSOR_THEME=Other XCURSOR_SIZE=24 /x/bin/weston --shell=kiosk -c /x/weston.ini"; } != [ ]);
    "fastfetch: the spec user has the ryoku-fastfetch wrapper in home.packages (base user does not); its script has the absolute ryoku-desktop-data, chafa, jq, sed and coreutils paths, the file-raw logo and the none fallback" =
      let
        named = c: lib.filter (p: lib.getName p == "ryoku-fastfetch") c.home.packages;
        t = if named hm == [ ] then "" else builtins.readFile "${lib.head (named hm)}/bin/ryoku-fastfetch";
      in
      yes "wrapper count ${toString (lib.length (named hm))}, base ${toString (lib.length (named baseHm))}, problems ${builtins.toJSON (probes.fastfetchWrapperProblems t)}"
        (lib.length (named hm) == 1 && named baseHm == [ ] && probes.fastfetchWrapperProblems t == [ ]);
    "control: the fastfetch wrapper probe flags a script without the logo-type branch or the TMUX test, and one that calls itself" =
      yes "probe silent"
        (probes.fastfetchWrapperProblems "real=/nix/store/aaaa-ryoku-desktop-data/bin/ryoku-fastfetch\nexec \"$real\" \"$@\"\n" != [ ]
          && probes.fastfetchWrapperProblems "real=/nix/store/aaaa-ryoku-fastfetch/bin/ryoku-fastfetch\n" != [ ]);
    "sddm cursor: /share/icons is linked into the spec's system profile" =
      yes "pathsToLink ${builtins.toJSON spec.environment.pathsToLink}" (lib.elem "/share/icons" spec.environment.pathsToLink);
    "sddm cursor: the base's sddm settings carry neither our cursor theme nor XCURSOR_PATH (control)" =
      yes "base theme ${builtins.toJSON (cursorTheme base)}, env ${builtins.toJSON (greeterEnv base)}"
        (cursorTheme base != "Bibata-Modern-Ice" && !(lib.elem xcursorEntry (greeterEnv base)));
    "sddm seed: the service exists exactly when impermanence and sddm are on in the spec, and never in the base" =
      yes "impermanence ${builtins.toJSON impOn}, sddm ${builtins.toJSON sddmOn}, seed present ${builtins.toJSON (sddmSeed != null)}, in base ${builtins.toJSON (base.systemd.services ? ryoku-sddm-theme-seed)}"
        ((sddmSeed != null) == (impOn && sddmOn) && !(base.systemd.services ? ryoku-sddm-theme-seed));
    "sddm seed: oneshot, wanted by and Before display-manager, RequiresMountsFor /var/lib/ryoku (when present)" =
      if sddmSeed == null then "ok"
      else
        yes "seed unit ${builtins.toJSON { inherit (sddmSeed) before wantedBy; mounts = sddmSeed.unitConfig.RequiresMountsFor or null; type = sddmSeed.serviceConfig.Type or null; }}"
          (sddmSeed.serviceConfig.Type == "oneshot" && lib.elem "display-manager.service" sddmSeed.before && lib.elem "display-manager.service" sddmSeed.wantedBy
            && lib.elem "/var/lib/ryoku" (lib.toList sddmSeed.unitConfig.RequiresMountsFor));
    "sddm seed: the script guards on Main.qml and calls every tool by absolute store path (when present)" =
      if sddmSeed == null then "ok"
      else
        yes "script lacks the Main.qml guard or a tool is called bare: ${builtins.toJSON (probes.bareToolLines sddmSeed.script)}"
          (lib.hasInfix "Main.qml" sddmSeed.script && lib.hasInfix "/nix/store/" sddmSeed.script && probes.bareToolLines sddmSeed.script == [ ]);

    "settings: the options settings (default {}) and settingsMode (default seed-once) are declared" =
      eq "defaults" [ sys.options.myconfig.specializations.ryoku.settings.default sys.options.myconfig.specializations.ryoku.settingsMode.default ] [{ } "seed-once"];
    "settings: no settings assertion fails on this host" = eq "failing settings assertions" failingSettings [ ];
    "settings: ryoku-settings-seed exists exactly when settings are declared, in the spec and not in the base" =
      yes "declared stores ${toString declaredStores}, unit ${builtins.toJSON (seedUnit != null)}, in base ${builtins.toJSON (base.systemd.user.services ? ryoku-settings-seed)}"
        ((seedUnit != null) == (declaredStores != [ ]) && !(base.systemd.user.services ? ryoku-settings-seed));
    "settings: unit ordering (after ryoku-materialize, before ryoku-shell, wanted by ryoku-session.target) and ConditionUser is the ryoku user" =
      if seedUnit == null then "ok"
      else
        yes "unit ${builtins.toJSON { inherit (seedUnit) after before requires wantedBy; cond = seedUnit.unitConfig.ConditionUser or null; }}"
          (lib.elem "ryoku-materialize.service" seedUnit.after && lib.elem "ryoku-materialize.service" seedUnit.requires
            && lib.elem "ryoku-shell.service" seedUnit.before && lib.elem "ryoku-session.target" seedUnit.wantedBy
            && seedUnit.unitConfig.ConditionUser == ryokuUser && ryokuUser != baseUser && seedUnit.serviceConfig.Type == "oneshot");
    "emblem: the krit layer leaves fastfetchEmblem null (a Hub/GUI choice) and the spec has no ryoku-fastfetch-emblem-seed unit; no hawk.png in the layer" =
      yes "value ${builtins.toJSON (if emblemValue == null then null else toString emblemValue)}, unit ${builtins.toJSON (emblemUnit != null)}"
        (emblemValue == null && emblemUnit == null && !(lib.hasInfix "hawk.png" (builtins.readFile (flake.outPath + "/users/krit/nixos/specializations/ryoku.nix"))));
    "control: the sentinel-order probe rejects a missing sentinel and a sentinel before save" =
      yes "probe accepts a bad script"
        (probes.sentinelAfterSave "x fastfetch save y\n: > \"$sentinel\"\n"
          && !(probes.sentinelAfterSave "x fastfetch save y\n")
          && !(probes.sentinelAfterSave ": > \"$sentinel\"\nx fastfetch save y\n"));
    "settings: the script has one seed call per declared store with a 16 hex sentinel hash, seed-once sentinels, no bare tool, flock only for desktop" =
      if seedUnit == null then "ok"
      else
        let
          missing = lib.filter (st: !(lib.any (storeLine st) seedLines)) declaredStores;
          callCount = lib.length (lib.filter (l: builtins.match ".*seed [a-z-]+ /nix/store/.*" l != null) seedLines);
        in
        yes "stores without a call: ${toString missing}, calls ${toString callCount} for ${toString (lib.length declaredStores)}, bare ${builtins.toJSON (probes.bareToolLines seedText)}"
          (missing == [ ] && callCount == lib.length declaredStores
            && lib.hasInfix "settings-seeded-$store-$hash" seedText && lib.hasInfix "mode=seed-once" seedText
            && probes.bareToolLines seedText == [ ]
            && (lib.elem "desktop" declaredStores == lib.hasInfix "bin/flock -x 9" seedText));
    "control: the sentinel-line probe rejects a call without hash and the bare-tool probe flags a bare command" =
      yes "probes accept a bad line"
        (!(storeLine "shell" "seed shell /nix/store/x-ryoku-settings-shell.json || rc=1") && storeLine "shell" "seed shell /nix/store/x-ryoku-settings-shell.json 0123456789abcdef || rc=1"
          && probes.bareToolLines "  jq . x\n  /nix/store/a/bin/jq . x" == [ "  jq . x" ]);

    "binds: hypr/user.lua and niri/user.kdl exist for the ryoku user with force = true, and not for the base user; no mango/user.conf is rendered" =
      yes "force ${builtins.toJSON (map (n: hmF.${n}.force) bindFiles)}, base has ${builtins.toJSON (map (n: baseHmF ? ${n}) bindFiles)}"
        (lib.all (n: hmF ? ${n} && hmF.${n}.force == true && !(baseHmF ? ${n})) bindFiles && !(hmF ? "mango/user.conf"));
    "binds: the rendered files carry none of vicinae, swayosd, swaync, waybar, grimblast" =
      let hits = map probes.legacyHits [ hyprT niriT ]; in
      yes "legacy words in the files: ${builtins.toJSON hits}" (hits == [ [ ] [ ] ]);
    "control: the legacy-word probe flags a legacy command" =
      yes "probe is blind" (probes.legacyHits "x vicinae toggle; swaync-client -t" == [ "vicinae" "swaync" ]);
    "binds: every file parses into binds and holds no duplicate chord" =
      let
        l = probes.luaBindChords hyprT;
        n = probes.niriChords niriT;
      in
      yes "counts ${toString [ (lib.length l) (lib.length n) ]}, duplicates ${builtins.toJSON [ (probes.dups l) (probes.dups n) ]}"
        (l != [ ] && n != [ ] && probes.dups l == [ ] && probes.dups n == [ ]);
    "control: the duplicate probes flag a repeated chord regardless of case and modifier order" =
      yes "a probe misses a duplicate"
        (probes.dups (probes.luaBindChords "hl.bind(\"SUPER + SHIFT + A\", x)\nhl.bind(\"SHIFT + SUPER + a\", y)\n") != [ ]
          && probes.dups (probes.niriChords "    Super+Shift+A { x; }\n    shift+super+a { y; }\n") != [ ]);
    "binds: hyprland unbinds every chord immediately before binding it" =
      yes "unbind/bind pairing broken" (probes.luaPairingOk hyprT);
    "control: the pairing probe rejects a bind without its unbind and a swapped pair" =
      yes "probe accepts a broken file"
        (!(probes.luaPairingOk "hl.bind(\"A\", x)\n") && !(probes.luaPairingOk "hl.bind(\"A\", x)\nhl.unbind(\"A\")\n") && probes.luaPairingOk "hl.unbind(\"A\")\nhl.bind(\"A\", x)\n");
    "binds: the base hyprland binds still hold the anchor chords (when hyprland is configured for the base user)" =
      if hyprBase == [ ] then "ok"
      else yes "missing anchors ${builtins.toJSON (lib.filter (a: !(lib.elem a hyprBaseChords)) hyprAnchors)}" (lib.all (a: lib.elem a hyprBaseChords) hyprAnchors);

    "personal: kitty.conf is forced off and replaced by user.conf in the ryoku home (when kitty is on)" =
      if !hm.programs.kitty.enable then "ok"
      else
        yes "kitty.conf enable ${builtins.toJSON hmF."kitty/kitty.conf".enable}, user.conf enable ${builtins.toJSON hmF."kitty/user.conf".enable or null}, base kitty.conf ${builtins.toJSON (baseHmF."kitty/kitty.conf".enable or null)}"
          (!hmF."kitty/kitty.conf".enable && hmF."kitty/user.conf".enable && baseHmF."kitty/kitty.conf".enable);
    "personal: config.fish is forced off and user.fish lacks the HM single-source guard line (when fish is on)" =
      if !hm.programs.fish.enable then "ok"
      else
        let
          guard = "set -q __fish_home_manager_config_sourced; and exit";
          userFish = builtins.readFile hmF."fish/user.fish".source;
          baseFish = builtins.readFile baseHmF."fish/config.fish".source;
        in
        yes "config.fish enable ${builtins.toJSON hmF."fish/config.fish".enable}, guard in user.fish ${builtins.toJSON (lib.hasInfix guard userFish)}, guard in base config.fish ${builtins.toJSON (lib.hasInfix guard baseFish)}"
          (!hmF."fish/config.fish".enable && hmF."fish/user.fish".enable && !(lib.hasInfix guard userFish) && lib.hasInfix guard baseFish);
    "personal: user.fish carries the eza aliases when eza is on" =
      if !(hm.programs.fish.enable && hm.programs.eza.enable) then "ok"
      else
        let t = builtins.readFile hmF."fish/user.fish".source; in
        yes "eza aliases missing from user.fish" (lib.hasInfix "alias ls eza" t && lib.hasInfix "alias ll 'eza -l'" t);
    "personal: yazi.toml is forced off and YAZI_CONFIG_HOME points at the link farm in home.sessionVariables and environment.sessionVariables (when yazi is on)" =
      if !hm.programs.yazi.enable then "ok"
      else
        let want = "${home}/.config/yazi-user"; in
        yes "yazi.toml enable ${builtins.toJSON hmF."yazi/yazi.toml".enable}, vars ${builtins.toJSON [ (hm.home.sessionVariables.YAZI_CONFIG_HOME or null) (spec.environment.sessionVariables.YAZI_CONFIG_HOME or null) ]}, base has the variable ${builtins.toJSON (base.environment.sessionVariables ? YAZI_CONFIG_HOME)}"
          (!hmF."yazi/yazi.toml".enable && hm.home.sessionVariables.YAZI_CONFIG_HOME == want && spec.environment.sessionVariables.YAZI_CONFIG_HOME == want
            && !(base.environment.sessionVariables ? YAZI_CONFIG_HOME));
    "personal: the yazi link farm contains yazi.toml (when yazi is on)" =
      if !hm.programs.yazi.enable then "ok"
      else yes "link farm lacks yazi.toml: ${builtins.toJSON (builtins.attrNames (builtins.readDir hmF."yazi-user".source))}" (builtins.readDir hmF."yazi-user".source ? "yazi.toml");
    "personal: home-manager.backupFileExtension is set (a stray file does not abort the activation)" =
      yes "backupFileExtension ${builtins.toJSON spec.home-manager.backupFileExtension}" (spec.home-manager.backupFileExtension or null != null);

    "audit: programs.dconf and services.fwupd are on in the spec" =
      eq "dconf, fwupd" [ spec.programs.dconf.enable spec.services.fwupd.enable ] [ true true ];
    "audit: wallpapersLink is false in the spec" =
      yes "wallpapersLink ${builtins.toJSON (optOf spec [ "services" "external" "dotfiles" "wallpapersLink" ])}"
        (!(declared [ "services" "external" "dotfiles" "wallpapersLink" ]) || optOf spec [ "services" "external" "dotfiles" "wallpapersLink" ] == false);
    "audit: the sops files of the re-enabled NAS secrets resolve to the literal krit-common-secrets-sops.yaml, exist, and equal the base's" =
      let
        names = lib.filter (n: spec.sops.secrets ? ${n} && base.sops.secrets ? ${n}) [ "nas-krit-credentials" "nas_ssh_key" ];
      in
      yes "secrets ${toString names}, files ${builtins.toJSON (map (n: toString (secretSops n)) names)}"
        (lib.all (n: lib.hasSuffix "/krit-common-secrets-sops.yaml" (toString (secretSops n)) && builtins.pathExists (secretSops n) && secretSops n == base.sops.secrets.${n}.sopsFile) names
          && (optOf spec [ "krit" "services" "nas" "smb" ] != true || names != [ ]));
    "control: the sops file probe rejects a per-user file name derived from the ryoku user and accepts the literal one" =
      yes "probe is wrong"
        (!(lib.hasSuffix "/krit-common-secrets-sops.yaml" "/x/${ryokuUser}-common-secrets-sops.yaml") && lib.hasSuffix "/krit-common-secrets-sops.yaml" "/x/krit-common-secrets-sops.yaml");
    "audit: ssh peer blocks use each peer's own user, never the ryoku user, in the system config and the home-manager settings" =
      let
        hmSettings = lib.attrByPath [ "programs" "ssh" "settings" ] { } hm;
        hmUserOf = p: (hmSettings.${p}.data or hmSettings.${p} or { }).User or null;
        extraOk = p: lib.hasInfix "Host ${p}\n  HostName ${p}\n  IdentityFile /home/${ryokuUser}/.ssh/id_github\n  IdentitiesOnly yes\n  User ${peerUserOf p}\n" sshExtra;
      in
      if !(spec.myconfig.krit.system.ssh-config.enable or false) then "ok"
      else
        yes "peers ${toString peers}, peer users ${builtins.toJSON (map peerUserOf peers)}, ryoku user ${ryokuUser}"
          (peers != [ ] && lib.all extraOk peers && lib.all (p: hmUserOf p == peerUserOf p && hmUserOf p != ryokuUser) peers
            && !(lib.hasInfix "User ${ryokuUser}\n" sshExtra));
    "audit: the spec's system ssh config has the gitea Host block (Port 2222, the ryoku user's id_github) and the pinned known host" =
      yes "extraConfig lacks the gitea block or knownHosts lacks the key: ${builtins.toJSON (lib.attrNames spec.programs.ssh.knownHosts)}"
        (lib.hasInfix "Host gitea-ssh.nicolkrit.ch\n  IdentityFile /home/${ryokuUser}/.ssh/id_github\n  IdentitiesOnly yes\n  Port 2222\n" sshExtra
          && spec.programs.ssh.knownHosts ? "[gitea-ssh.nicolkrit.ch]:2222");
    "audit: the sops-common alias points at an existing users/<dir>/common/sops file and not at the ryoku user's name" =
      let
        dir = if aliasMatch == null then "" else builtins.elemAt aliasMatch 0;
        file = if aliasMatch == null then "" else builtins.elemAt aliasMatch 1;
      in
      yes "alias ${builtins.toJSON sopsAlias}"
        (aliasMatch != null && dir != ryokuUser && file == "${dir}-common-secrets-sops.yaml" && builtins.pathExists "${root}/users/${dir}/common/sops/${file}");
    "control: the alias probe does not match a made-up alias" =
      yes "probe matches" (builtins.match "cd [^ ]*/users/([^/ ]+)/common/sops && sops ([^ ]+)" "cd ~/x && sops y" == null);

    "stylix-lite: stylix is on with autoEnable false at the NixOS and home-manager level" =
      eq "enable/autoEnable (nixos, hm)" [ spec.stylix.enable spec.stylix.autoEnable hm.stylix.enable hm.stylix.autoEnable ] [ true false true false ];
    "stylix-lite: the home-manager targets that are on are exactly the non-clashing set" =
      eq "hm targets on" hmTargetsOn (lib.sort (a: b: a < b) stylixOn);
    "stylix-lite: the repo-level targets mirror the set (on and off lists)" =
      eq "myconfig.stylix.targets" (lib.mapAttrs (_: t: t.enable) (lib.getAttrs (stylixOn ++ [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" ]) spec.myconfig.stylix.targets))
        (lib.genAttrs stylixOn (_: true) // lib.genAttrs [ "gtk" "hyprland" "kde" "kitty" "starship" "swaync" "yazi" ] (_: false));
    "stylix-lite: the clashing targets (gtk, hyprland, kde, kitty, starship, swaync, yazi, fonts, icons) are off" =
      yes "still on: ${toString (lib.filter (n: hm.stylix.targets.${n}.enable) stylixOff)}" (lib.all (n: !hm.stylix.targets.${n}.enable) stylixOff);
    "control: the base user's stylix has more targets on, including the clashing font targets" =
      yes "base targets on: ${toString (lib.length (lib.filter (n: baseHm.stylix.targets.${n}.enable or false == true) (lib.attrNames baseHm.stylix.targets)))}"
        (lib.length (lib.filter (n: baseHm.stylix.targets.${n}.enable or false == true) (lib.attrNames baseHm.stylix.targets)) > lib.length stylixOn
          && lib.all (n: baseHm.stylix.targets.${n}.enable) [ "fontconfig" "font-packages" ]);
    "stylix-lite: the colour scheme and image equal the base's at both levels" =
      eq "scheme equality" [ spec.stylix.base16Scheme hm.stylix.base16Scheme ] [ base.stylix.base16Scheme baseHm.stylix.base16Scheme ];
    "stylix-lite: catppuccin.eza follows the base theme (the constant is false in the spec)" =
      eq "catppuccin.eza" [ spec.myconfig.constants.theme.catppuccin (hm.catppuccin.eza.enable or false) ] [ false (base.myconfig.constants.theme.catppuccin && hm.programs.eza.enable) ];
    "apps: settings.desktop.desktop.apps derive from the constants (browser, terminal, terminal-wrapped editor, file manager, notes)" =
      eq "apps" appsCfg { inherit (bc) browser; terminal = bc.terminal.name; editor = inTerm bc.editor; files = inTerm bc.fileManager; notes = inTerm bc.editor; };
    "apps: the rendered defaults are the known values of the current constants (anchor)" =
      eq "apps" appsCfg { browser = "zen-beta"; terminal = "kitty"; editor = "kitty -e nvim"; files = "kitty -e yazi"; notes = "kitty -e nvim"; };
    "input: kbLayout and kbVariant are the first entry of the constants lists, kbOptions is empty, naturalScroll false" =
      eq "input" inputCfg
        (inputCfg // { kbLayout = firstOf bc.keyboardLayout; kbVariant = firstOf bc.keyboardVariant; kbOptions = ""; naturalScroll = false; });
    "input: the rendered layout and variant are the known values of the current constants (anchor)" =
      eq "kb" [ inputCfg.kbLayout inputCfg.kbVariant ] [ "us" "alt-intl" ];
    "matugen: the store follows constants.theme.polarity with expressive scheme, darkness, contrast 0" =
      eq "matugen" matugenCfg { mode = bc.theme.polarity; schemeType = "scheme-expressive"; prefer = "darkness"; contrast = 0; };
    "matugen: the shell and ryogami modes agree with the polarity (shell capitalised)" =
      eq "modes" [ declared_.shell.theme.matugen.mode declared_.ryogami.matugen.mode ] [ (lib.toUpper (lib.substring 0 1 bc.theme.polarity) + lib.substring 1 (-1) bc.theme.polarity) bc.theme.polarity ];
    "home: myconfig.specializations.ryoku.user and .home equal the spec user's account and home" =
      eq "user/home" [ base.myconfig.specializations.ryoku.user base.myconfig.specializations.ryoku.home ] [ ryokuUser home ];
    "launcher: heroImage is file:// plus the ryoku home plus the wallpaper path" =
      eq "heroImage" declared_.launcher.heroImage "file://${home}/Pictures/Wallpapers/wallhaven-vpyrm5.jpg";
    "theme store: theme.scheme is not declared" =
      yes "settings.theme ${builtins.toJSON (declared_.theme or { })}" (!(declared_.theme or { } ? scheme));
    "apps: programs.ryoku.browser stays null in the spec" = eq "programs.ryoku.browser" spec.programs.ryoku.browser null;
  } // offChecks;

  safe = v: let t = builtins.tryEval (builtins.deepSeq v v); in if t.success then t.value else "FAIL: eval error";
in
{
  inherit checks;
  results = lib.mapAttrs (_: safe) checks;
}
