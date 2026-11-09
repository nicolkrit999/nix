let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  base = flake.nixosConfigurations.${host}.config;
  spec = base.specialisation.school.configuration;
  c = spec.config or spec;
  baseUser = base.myconfig.constants.user;
  userName = c.myconfig.constants.user;
  hm = c.home-manager.users.${userName};
  baseHm = base.home-manager.users.${baseUser};
  home = hm.home.homeDirectory;
  baseHome = base.users.users.${baseUser}.home;
  mountPoint = "${home}/opencloud";
  sysPkgs = flake.nixosConfigurations.${host}.pkgs;
  braveBin = builtins.unsafeDiscardStringContext "${sysPkgs.brave}/bin/brave";

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";
  data = s: s.data or s;
  sshOf = h: n: data (h.programs.ssh.settings.${n} or { });

  hasPkgInfix = s: pkgs: lib.any (p: lib.hasInfix s (p.name or "")) pkgs;
  pkgByName = n: lib.findFirst (p: (p.name or "") == n) null hm.home.packages;
  scriptText = n: let p = pkgByName n; in if p == null then "" else p.text;
  scriptNames = [
    "tkgate-school"
    "sqldeveloper-school"
    "school-distrobox-setup"
    "school-distrobox-check"
    "school-distrobox-clear"
  ];

  monitors = lib.filter (m: m.output != "" && !(m ? mirror) && (m.mode or "") != "disable") c.myconfig.programs.hyprland.monitors;
  scales = lib.unique (map (m: m.scale) monitors);
  scale = lib.head scales;
  scaleStr = toString scale;

  uiScaleOf = text:
    let m = builtins.match ".*uiScale=([0-9.]+).*" text;
    in if m == null then null else builtins.fromJSON (lib.head m);

  allSpaces = c.myconfig.krit.services.nas.opencloud-mount.spaces;
  spaces = lib.filter (s: lib.hasPrefix "University/" s.path) allSpaces;
  fsName = s: "${mountPoint}/${s.path}";
  schoolFs = lib.filterAttrs (n: _: lib.hasPrefix "${mountPoint}/" n) c.fileSystems;
  optsOf = s: (c.fileSystems.${fsName s} or { options = [ ]; }).options;
  davfsRequired = [ "noauto" "nofail" "x-systemd.automount" "_netdev" ];
  optEquals = key: val: opts: lib.elem "${key}=${val}" opts;
  badFs = pred: map (s: s.path) (lib.filter (s: !(pred s)) spaces);

  unit = c.systemd.services.tailscale-school-exit-node-off or null;
  unitDeps = if unit == null then [ ] else unit.after ++ unit.wants;
  serviceExists = u: c.systemd.services ? ${lib.removeSuffix ".service" u};

  gitSet = hm.programs.git.settings;
  signers = hm.home.file.".ssh/allowed_signers";
  signerFields = lib.splitString " " (lib.head (lib.splitString "\n" (lib.trim signers.text)));
  idFile = c.sops.secrets.school_ssh_key.path;
  signerLines = lib.splitString "\n" (lib.trim signers.text);
  baseSignerLines = lib.splitString "\n" (lib.trim baseHm.home.file.".ssh/allowed_signers".text);
  principalOf = l: lib.head (lib.splitString " " l);

  githubPin = (c.programs.ssh.knownHosts."github.com" or { publicKey = null; }).publicKey;

  leftoverWrappers = lib.filter (n: lib.hasPrefix "brave-school" n || lib.hasPrefix "vscode-school" n || lib.hasPrefix "idea-school" n) (map (p: p.name or "") hm.home.packages);
  plainApps = [ "brave" "vscode" "intellij-idea" "proton-pass" "drawio" "pay-respects" "tealdeer" "teams-for-linux" ];
  installedAs = pkg: lib.any (p: (p.name or "") == pkg.name) hm.home.packages;
  missingPlain = lib.filter (n: !(installedAs sysPkgs.${n})) plainApps;
  pwaBrave = e: lib.hasPrefix "${braveBin} --app=" (e.exec or "");
  pwaIconNames = [ "school-pwa-icorsi" "school-pwa-supsi-portal" ];
  iconIsStorePng = i: lib.hasPrefix "/nix/store/" i && lib.hasSuffix ".png" i;
  iconDrvs = i: lib.length (lib.attrNames (lib.filterAttrs (_: v: v ? path || v ? outputs) (builtins.getContext i)));
  yearDirs = [ "1st/1-semester" "1st/2-semester" "2nd/3-semester" "2nd/4-semester" "3rd/5-semester" "3rd/6-semester" ];
  userDirsFile = hm.xdg.configFile."user-dirs.dirs".text;
  baseUserDirsFile = baseHm.xdg.configFile."user-dirs.dirs".text;
  xdgMkdirs = hm.home.activation.createXdgUserDirectories.data;
  baseXdgMkdirs = baseHm.home.activation.createXdgUserDirectories.data;
  leftoversText = hm.home.activation.removeEmptySchoolLeftovers.data;
  leftoverTargets = [
    "year/1st/1-semester"
    "year/1st/2-semester"
    "year/2nd/3-semester"
    "year/2nd/4-semester"
    "year/3rd/5-semester"
    "year/3rd/6-semester"
    "year/1st"
    "year/2nd"
    "year/3rd"
    "year"
    "projects"
  ];
  idxOf = sub: text: let parts = lib.splitString sub text; in if lib.length parts < 2 then -1 else lib.stringLength (lib.head parts);
  leftoversOkFor = text:
    lib.hasInfix "rmdir -- \"$d\"" text
    && !(lib.hasInfix "rm -" text) && !(lib.hasInfix "find " text) && !(lib.hasInfix "-delete" text)
    && lib.all (t: lib.hasInfix "\"$HOME/${t}\"" text) leftoverTargets
    && lib.all (t: idxOf "\"$HOME/${t}\"" text >= 0) leftoverTargets
    && lib.all (p: idxOf "\"$HOME/${p.a}\"" text < idxOf "\"$HOME/${p.b}\"" text) [
      { a = "year/1st/1-semester"; b = "year/1st"; }
      { a = "year/3rd/6-semester"; b = "year/3rd"; }
      { a = "year/1st"; b = "year"; }
      { a = "year/3rd"; b = "year"; }
    ];
  leftoversOk =
    leftoversOkFor leftoversText
    && lib.elem "createSchoolDirs" (hm.home.activation.removeEmptySchoolLeftovers.after or [ ]);
  schoolActivationTexts = map (n: hm.home.activation.${n}.data or "") (lib.filter (n: lib.elem n [ "createSchoolDirs" "removeEmptySchoolLeftovers" ]) (lib.attrNames hm.home.activation));
  hmTmpfiles = hm.systemd.user.tmpfiles.rules or [ ];

  entries = hm.xdg.desktopEntries;
  pwaNames = lib.filter (lib.hasPrefix "school-pwa-") (lib.attrNames entries);
  pwaOk = e: (e.mimeType or null) == null && (e.categories or null) == [ "Education" ];
  pwaBad = pred: lib.filter (n: !(pred entries.${n})) pwaNames;
  onedrive = hm.systemd.user.services.rclone-mount-school-onedrive;
  onedriveUnit = onedrive.Unit;
  createDirs = hm.home.activation.createSchoolDirs.data;
  anyHas = needle: lib.any (lib.hasInfix needle);

  workspacesOf = line: map lib.head (builtins.filter (m: m != null) (map (builtins.match "\\[workspace ([0-9]+).*") [ line ]));
  execWs = lib.concatMap workspacesOf c.myconfig.programs.hyprland.execOnce;
  declaredWs = map (m: m.workspace) c.myconfig.programs.hyprland.monitorWorkspaces;

  setup = scriptText "school-distrobox-setup";
  clear = scriptText "school-distrobox-clear";
  checkQuoted = builtins.length (lib.filter builtins.isList (builtins.split "bash -c '[^'\n]*' &>/dev/null" setup));

  sshHosts = [ "github.com" "gitlab.com" "gitlab-edu.supsi.ch" ];
  sshBad = pred: lib.filter (h: !(pred (sshOf hm h))) sshHosts;

  isLaptop = c.myconfig.constants.hostname == "nixos-laptop";

  printingProbe = cfg: names: lib.concatLists [
    (lib.optional (cfg.services.printing.enable or false) "cups")
    (lib.optional (cfg.environment.etc ? ${names.etc}) "etc")
    (lib.optional (cfg.systemd.services ? ${names.service}) "service")
    (lib.optional (cfg.sops.secrets ? ${names.secret}) "secret")
  ];
  printingNames = { etc = "samba/smb.conf"; service = "supsi-printer-setup"; secret = "school_supsi_password"; };
  knownNames = { etc = "davfs2/secrets"; service = "tailscaled-autoconnect"; secret = "school_ssh_key"; };

  schoolUid = c.users.users.${userName}.uid;
  rangeOf = u: kind: map (r: { start = r.startUid or r.startGid; inherit (r) count; }) (u.${kind} or [ ]);
  overlaps = a: b: lib.any (x: lib.any (y: x.start < y.start + y.count && y.start < x.start + x.count) b) a;
  schoolGroups = c.users.users.${userName}.extraGroups;
  baseGroups = base.users.users.${baseUser}.extraGroups;

  mcpNames = map (m: m.sopsSecret) c.myconfig.krit.programs.claude-code-personal.mcpSecrets;
  claudeSecretNames = mcpNames ++ [ "cf_account_id" "cf_api_token" ];

  claims = u: attrs: lib.filterAttrs (_: v: (v.owner or null) == u || lib.hasPrefix "/home/${u}/" (v.path or "")) attrs;
  mentionsUser = u: l: lib.hasInfix " ${u} " l || lib.hasInfix "/home/${u}/" l;

  personalOptions = [
    [ "krit" "services" "cloud" "googleDrive" ]
    [ "krit" "services" "cloud" "onedrivePersonal" ]
    [ "krit" "services" "cloud" "pcloud" ]
    [ "krit" "services" "cloud" "protonDrive" ]
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
    [ "krit" "services" "nas" "opencloud-mount" ]
    [ "krit" "services" "nas" "smb" ]
    [ "krit" "services" "nas" "sshfs" ]
    [ "krit" "services" "windows-mount" ]
    [ "krit" "services" "desktop" "flatpak" ]
    [ "krit" "services" "laptop" "flatpak" ]
    [ "krit" "services" "desktop" "local-packages" ]
    [ "krit" "services" "laptop" "local-packages" ]
    [ "krit" "system" "ssh-config" ]
    [ "krit" "home" "base" ]
    [ "krit" "programs" "dolphin" ]
    [ "krit" "programs" "proton-cli" ]
    [ "krit" "programs" "pwas" ]
    [ "krit" "services" "network-tools" ]
    [ "programs" "concord" ]
    [ "programs" "npm" ]
    [ "programs" "openlogi" ]
    [ "programs" "prismlauncher" ]
    [ "programs" "thunderbird" ]
    [ "programs" "zapfast" ]
    [ "services" "external" "dotfiles-private" ]
    [ "services" "snapshots" ]
  ];
  reEnabled = [
    [ "krit" "programs" "claude-code-wrappers" ]
    [ "krit" "programs" "claude-code-personal" ]
    [ "krit" "programs" "discord" ]
    [ "programs" "discord" ]
    [ "programs" "claude-desktop" ]
    [ "programs" "agent-reach" ]
    [ "programs" "vikunja-desktop" ]
    [ "programs" "spotifyAdblock" ]
    [ "programs" "sidra" ]
  ];
  reEnabledOff = cfg: lib.filter (p: optOf cfg p != true) reEnabled;
  optOf = cfg: path: lib.attrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) null cfg;
  declaredPersonal = lib.filter (p: optOf c p != null) personalOptions;
  stillOn = cfg: lib.filter (p: optOf cfg p == true) declaredPersonal;
  showPath = p: lib.concatStringsSep "." p;

  schoolMountNames = lib.attrNames schoolFs;
  wantedMountNames = map (s: "${mountPoint}/${s.path}") spaces;

  desktopWant = { hyprland = true; kde = true; niri = false; mango = false; cosmic = false; gnome = false; caelestia = false; noctalia = false; };
  deOf = cfg: n: cfg.myconfig.programs.${n}.enable;
  deBad = lib.filter (n: deOf c n != desktopWant.${n}) (lib.attrNames desktopWant);

  hyprExec = c.myconfig.programs.hyprland.execOnce;
  homeRelative = l: !(lib.hasInfix "/home/" l) && !(lib.hasInfix "~" l);

  needle = ".school-workspace";
  userServiceExecs = lib.concatLists (lib.mapAttrsToList (_: svc: map toString (lib.toList (svc.Service.ExecStart or [ ]))) hm.systemd.user.services);
  workspaceHaystack =
    c.systemd.tmpfiles.rules
    ++ hyprExec
    ++ c.myconfig.programs.niri.execOnce
    ++ c.myconfig.programs.mango.execOnce
    ++ [ hm.home.activation.createSchoolDirs.data hm.programs.bash.initExtra syncText ]
    ++ map (p: toString (p.text or "")) hm.home.packages
    ++ lib.attrNames hm.home.file
    ++ map (e: toString (e.exec or "")) (lib.attrValues hm.xdg.desktopEntries)
    ++ userServiceExecs;
  anyNeedle = n: hay: lib.any (lib.hasInfix n) hay;

  zenOf = h: h.programs.zen-browser.profiles.default;
  z = zenOf hm;
  bz = zenOf baseHm;
  uni = z.spaces.University or { };

  mounts = c.myconfig.services.rcloneMount.mounts;
  baseMounts = base.myconfig.services.rcloneMount.mounts;
  m0 = lib.head mounts;
  rcloneUnit = hm.systemd.user.services.rclone-mount-school-onedrive;

  syncText = c.systemd.services.school-claude-sync.script;
  sync = c.systemd.services.school-claude-sync;
  dotfilesUnit = hm.systemd.user.services.school-dotfiles-sync;
  nixSyncUnit = hm.systemd.user.services.school-nix-sync;
  syncTarget = "${home}/${c.myconfig.constants.flakeDir}";
  devEnvStdlib = hm.programs.direnv.stdlib or "";
  countOf = sub: text: lib.length (lib.splitString sub text) - 1;
  setupText = scriptText "school-distrobox-setup";
  checkText = scriptText "school-distrobox-check";
  hostArgSites = countOf "_ \"$HOST_ARG\"" setupText;

  cleanupFn = let parts = lib.splitString "cleanup_staged() {\n" setupText; in if lib.length parts < 2 then "" else lib.head (lib.splitString "\n}\n" (lib.elemAt parts 1));
  stageOrder = [ "school-sqldeveloper-rpm-resolve" "school-stage-file" "HOST_ARG=\"$STAGED_FILE\"" "_ \"$HOST_ARG\"" ];
  stageIdx = map (m: idxOf m setupText) stageOrder;

  schoolUserChecks = [
    [ "school user is krit-school with uid 1001, home /home/krit-school and a uid different from the base user" (chk (userName == "krit-school" && schoolUid == 1001 && c.users.users.${userName}.home == "/home/${userName}" && schoolUid != base.users.users.${baseUser}.uid && userName != baseUser) "user ${userName}, uid ${toString schoolUid}, home ${c.users.users.${userName}.home}, base uid ${toString base.users.users.${baseUser}.uid}") ]
    [ "users.users.<base user> does not exist in the spec; the school user does" (chk (!(c.users.users ? ${baseUser}) && c.users.users ? ${userName}) "spec users: base user present=${lib.boolToString (c.users.users ? ${baseUser})}") ]
    [ "control: the base config has users.users.<base user> and not the school user (the existence probe bites)" (chk (base.users.users ? ${baseUser} && !(base.users.users ? ${userName})) "base users do not look as expected") ]
    [ "subuid/subgid ranges are 165536/65536 and do not overlap the base user's ranges" (chk (lib.all (k: rangeOf c.users.users.${userName} k == [{ start = 165536; count = 65536; }] && !(overlaps (rangeOf c.users.users.${userName} k) (rangeOf base.users.users.${baseUser} k)) && rangeOf base.users.users.${baseUser} k != [ ]) [ "subUidRanges" "subGidRanges" ]) "ranges: ${builtins.toJSON (rangeOf c.users.users.${userName} "subUidRanges")} vs base ${builtins.toJSON (rangeOf base.users.users.${baseUser} "subUidRanges")}") ]
    [ "control: the range overlap probe flags overlapping ranges and accepts disjoint ones" (chk (overlaps [{ start = 100; count = 50; }] [{ start = 120; count = 10; }] && !(overlaps [{ start = 100; count = 50; }] [{ start = 150; count = 10; }])) "overlap probe is wrong") ]
    [ "school user keeps every group of the base user and adds davfs2 and wireshark" (chk (baseGroups != [ ] && lib.subtractLists schoolGroups baseGroups == [ ] && lib.elem "davfs2" schoolGroups && lib.elem "wireshark" schoolGroups) "missing groups: ${toString (lib.subtractLists schoolGroups baseGroups)}") ]
    [ "login password of the school user and root is the sops krit-local-password" (chk (c.sops.secrets.krit-local-password.neededForUsers && c.users.users.${userName}.hashedPasswordFile == c.sops.secrets.krit-local-password.path && c.users.users.root.hashedPasswordFile == c.sops.secrets.krit-local-password.path) "hashedPasswordFile of the school user or root is not the sops secret") ]

    [ "home-manager.users is exactly the school user in the spec and exactly the base user in the base" (chk (lib.attrNames c.home-manager.users == [ userName ] && lib.attrNames base.home-manager.users == [ baseUser ]) "spec users ${toString (lib.attrNames c.home-manager.users)}, base users ${toString (lib.attrNames base.home-manager.users)}") ]

    [ "no sops secret or template in the spec is owned by or placed under the base user" (chk (claims baseUser c.sops.secrets == { } && claims baseUser c.sops.templates == { }) "base user owns: ${toString (lib.attrNames (claims baseUser c.sops.secrets // claims baseUser c.sops.templates))}") ]
    [ "control: the base config has secrets owned by or placed under the base user (the claim probe bites)" (chk (claims baseUser base.sops.secrets != { } && claims baseUser { x = { owner = baseUser; }; y = { path = "/home/${baseUser}/.ssh/k"; }; z = { owner = "root"; path = "/run/z"; }; } == { x = { owner = baseUser; }; y = { path = "/home/${baseUser}/.ssh/k"; }; }) "base has no such secret or the probe is wrong") ]
    [ "no tmpfiles rule, fileSystem or sops path in the spec names the base user's home" (chk (!(lib.any (mentionsUser baseUser) c.systemd.tmpfiles.rules) && !(lib.any (lib.hasPrefix "${baseHome}/") (lib.attrNames c.fileSystems))) "a rule or mount still names ${baseHome}") ]
    [ "school secrets (ssh key and pub, rclone OneDrive config) are owned by the school user" (chk (lib.all (n: (c.sops.secrets.${n}.owner or null) == userName) [ "school_ssh_key" "school_ssh_pub" "rclone_school_onedrive_conf" ]) "owners: ${toString (map (n: "${n}=${c.sops.secrets.${n}.owner or "unset"}") [ "school_ssh_key" "school_ssh_pub" "rclone_school_onedrive_conf" ])}") ]
    [ "attic, cachix and github PAT tokens are root-owned in the spec and owned by the base user in the base (control)" (chk (lib.all (n: c.sops.secrets.${n}.owner == "root" && base.sops.secrets.${n}.owner == baseUser) [ "attic-push-token" "cachix-push-token" "github_fg_pat_token_nix" ]) "token owners differ from root (spec) / base user (base)") ]
    [ "claude-code-personal secrets (the MCP keys and cf_account_id/cf_api_token) are declared in the spec, owned by the school user and not by the base user" (chk (mcpNames != [ ] && lib.all (n: c.sops.secrets ? ${n} && c.sops.secrets.${n}.owner == userName) claudeSecretNames) "missing or wrongly owned: ${toString (lib.filter (n: !(c.sops.secrets ? ${n}) || c.sops.secrets.${n}.owner != userName) claudeSecretNames)}") ]
    [ "control: the base declares the same claude-code-personal secrets, owned by the base user (the ownership probe bites)" (chk (lib.all (n: base.sops.secrets ? ${n} && base.sops.secrets.${n}.owner == baseUser) claudeSecretNames) "base lacks or does not own: ${toString (lib.filter (n: !(base.sops.secrets ? ${n}) || base.sops.secrets.${n}.owner != baseUser) claudeSecretNames)}") ]
    [ "no github_general_ssh_* or hevy_api_key secret in the spec, all present in the base (control)" (chk (lib.all (n: !(c.sops.secrets ? ${n}) && base.sops.secrets ? ${n}) [ "github_general_ssh_key" "github_general_ssh_pub" "hevy_api_key" ]) "personal secrets leak into the spec or the base lacks them (vacuous)") ]

    [ "personal modules (clouds, NAS, borg, windows-mount, flatpak, local-packages, ssh-config, dotfiles-private, snapshots, home base, dolphin, proton-cli, pwas, network-tools, concord, npm, openlogi, prismlauncher, thunderbird, zapfast) are off in the spec" (chk (declaredPersonal != [ ] && stillOn c == [ ]) "still on in the spec: ${toString (map showPath (stillOn c))}") ]
    [ "control: the same personal modules are on in the base (the off-probe bites)" (chk (stillOn base != [ ]) "no probed module is on in the base, the off check is vacuous") ]
    [ "re-enabled in the spec (not switched off): claude-code-wrappers, claude-code-personal, krit and generic discord, claude-desktop, agent-reach, vikunja-desktop, spotifyAdblock, sidra" (chk (reEnabledOff c == [ ]) "not on in the spec: ${toString (map showPath (reEnabledOff c))}") ]
    [ "control: the re-enabled apps are on in the base too, so the spec cannot be reading a default (on-probe bites)" (chk (reEnabledOff base == [ ]) "not on in the base: ${toString (map showPath (reEnabledOff base))}") ]
    [ "control: the on-probe reports a module the spec switches off (smb) and an undeclared one" (chk (lib.filter (p: optOf c p != true) [ [ "krit" "services" "nas" "smb" ] [ "no" "such" "module" ] ] == [ [ "krit" "services" "nas" "smb" ] [ "no" "such" "module" ] ]) "on-probe accepts an off or undeclared module") ]
    [ "no /mnt filesystem and no cifs, sshfs or ntfs3 mount in the spec; the base has /mnt mounts (control)" (chk (!(lib.any (lib.hasPrefix "/mnt/") (lib.attrNames c.fileSystems)) && !(lib.any (f: lib.elem f.fsType [ "cifs" "fuse.sshfs" "ntfs3" ]) (lib.attrValues c.fileSystems)) && lib.any (lib.hasPrefix "/mnt/") (lib.attrNames base.fileSystems)) "spec mounts: ${toString (lib.filter (lib.hasPrefix "/mnt/") (lib.attrNames c.fileSystems))}") ]
    [ "rcloneMount carries exactly the school OneDrive mount, not the base cloud mounts" (chk (map (m: m.name) mounts == [ "school-onedrive" ] && baseMounts != [ ] && !(lib.any (m: m.name == "school-onedrive") baseMounts)) "spec mounts ${toString (map (m: m.name) mounts)}, base mounts ${toString (map (m: m.name) baseMounts)}") ]

    [ "davfs mounts are exactly the University spaces under ~/opencloud, no Personal space" (chk (lib.sort (a: b: a < b) schoolMountNames == lib.sort (a: b: a < b) wantedMountNames && spaces != [ ] && !(lib.any (lib.hasInfix "Personal") (lib.attrNames c.fileSystems)) && lib.all (n: lib.hasPrefix "${mountPoint}/University/" n) schoolMountNames) "mounts ${toString schoolMountNames}, wanted ${toString wantedMountNames}") ]
    [ "control: the module's space list also holds a non-University space (the University filter bites)" (chk (lib.any (s: !(lib.hasPrefix "University/" s.path)) allSpaces) "all spaces are University spaces, the filter check is vacuous") ]
    [ "every davfs fileSystem of the spec lives under ~/opencloud" (chk (lib.all (n: lib.hasPrefix "${mountPoint}/" n) (lib.attrNames (lib.filterAttrs (_: f: f.fsType == "davfs") c.fileSystems))) "davfs outside ~/opencloud: ${toString (lib.attrNames (lib.filterAttrs (n: f: f.fsType == "davfs" && !(lib.hasPrefix "${mountPoint}/" n)) c.fileSystems))}") ]
    [ "tmpfiles creates ~/opencloud and ~/opencloud/University for the school user" (chk (lib.elem "d ${home}/opencloud 0700 ${userName} ${c.users.users.${userName}.group} -" c.systemd.tmpfiles.rules && lib.elem "d ${home}/opencloud/University 0700 ${userName} ${c.users.users.${userName}.group} -" c.systemd.tmpfiles.rules) "tmpfiles rules lack the opencloud directories") ]

    [ "no .school-workspace in the spec's tmpfiles, autostart, activation, scripts, desktop entries, home files or user units" (chk (!(anyNeedle needle workspaceHaystack) && !(anyNeedle "school-workspace" workspaceHaystack)) "a spec string still names the old workspace") ]
    [ "control: the .school-workspace probe finds the needle in a haystack that contains it" (chk (anyNeedle needle (workspaceHaystack ++ [ "d /home/x/.school-workspace 0755" ])) "needle probe cannot see the string") ]
    [ "school workspace is $HOME: .learning and distrobox-bin are local, sessionPath lists $HOME/distrobox-bin" (chk (lib.hasInfix "\"$HOME/.learning\"" createDirs && lib.hasInfix "\"$HOME/distrobox-bin\"" createDirs && lib.elem "$HOME/distrobox-bin" hm.home.sessionPath && lib.hasInfix "EXPORT_PATH=\"$HOME/distrobox-bin\"" setup && lib.hasInfix "EXPORT_PATH=\"$HOME/distrobox-bin\"" clear && !(lib.hasInfix ".distrobox-bin" setup)) "workspace dirs or distrobox-bin path differ") ]

    [ "hyprland autostart is non-empty, starts nvim and yazi in $HOME and names no /home or ~ path" (chk (hyprExec != [ ] && lib.all homeRelative hyprExec && anyHas "-d $HOME -e nvim" hyprExec && anyHas "-d $HOME -e yazi" hyprExec) "autostart: ${toString hyprExec}") ]
    [ "control: the home-relative probe rejects an absolute /home path and a ~ path" (chk (!(homeRelative "kitty -d /home/${userName}") && !(homeRelative "kitty -d ~/x") && homeRelative "kitty -d $HOME") "probe accepts absolute home paths") ]
    [ "desktops: hyprland and kde on; niri, mango, cosmic, gnome, caelestia, noctalia off" (chk (deBad == [ ]) "wrong state for: ${toString deBad}") ]
    [ "control: at least one of the off desktops is on in the base (the desktop probe bites)" (chk (lib.any (n: !desktopWant.${n} && deOf base n) (lib.attrNames desktopWant)) "no desktop is on in the base that the spec turns off") ]

    [ "constants: browser zen-beta, editor nvim, fileManager yazi, shell bash" (chk (c.myconfig.constants.browser == "zen-beta" && c.myconfig.constants.editor == "nvim" && c.myconfig.constants.fileManager == "yazi" && c.myconfig.constants.shell == "bash") "browser ${c.myconfig.constants.browser}, editor ${c.myconfig.constants.editor}, fileManager ${c.myconfig.constants.fileManager}, shell ${c.myconfig.constants.shell}") ]
    [ "mime document, sheet and slide editors are libreoffice" (chk (c.myconfig.mime.docEditor == "libreoffice" && c.myconfig.mime.sheetEditor == "libreoffice" && c.myconfig.mime.slideEditor == "libreoffice") "mime editors: ${c.myconfig.mime.docEditor} ${c.myconfig.mime.sheetEditor} ${c.myconfig.mime.slideEditor}") ]
    [ "control: the base browser differs from the spec's (the constants check can fail)" (chk (base.myconfig.constants.browser != c.myconfig.constants.browser || base.myconfig.constants.editor != c.myconfig.constants.editor || base.myconfig.constants.shell != c.myconfig.constants.shell) "base constants equal the spec's") ]

    [ "zen: universityOnly leaves exactly one space University and one container University with id 4" (chk (c.myconfig.krit.programs.zen-browser.universityOnly && lib.attrNames z.spaces == [ "University" ] && lib.attrNames z.containers == [ "University" ] && z.containers.University.id == 4 && uni.container == 4) "spaces ${toString (lib.attrNames z.spaces)}, containers ${toString (lib.attrNames z.containers)}") ]
    [ "zen: every remaining pin belongs to the University space and exists in the base pins" (chk (z.pins != { } && lib.all (n: z.pins.${n}.workspace == uni.id && bz.pins ? ${n}) (lib.attrNames z.pins)) "foreign pins: ${toString (lib.filter (n: z.pins.${n}.workspace != uni.id || !(bz.pins ? ${n})) (lib.attrNames z.pins))}") ]
    [ "control: the base zen profile keeps all spaces and strictly more pins (universityOnly is spec-only)" (chk (!base.myconfig.krit.programs.zen-browser.universityOnly && lib.length (lib.attrNames bz.spaces) > 1 && lib.elem "University" (lib.attrNames bz.spaces) && lib.length (lib.attrNames bz.pins) > lib.length (lib.attrNames z.pins)) "base zen profile is already restricted") ]

    [ "rcloneMount school-onedrive: remote school-onedrive:, config is the sops secret path, mount point under the school home" (chk (m0.remote == "school-onedrive:" && m0.configFile == c.sops.secrets.rclone_school_onedrive_conf.path && lib.hasPrefix "${home}/" m0.mountPoint && lib.elem "d ${m0.mountPoint} 0755 ${userName} users -" c.systemd.tmpfiles.rules) "mount ${builtins.toJSON m0}") ]
    [ "rcloneMount unit rclone-mount-school-onedrive mounts the remote on the mount point and replaces the old school-onedrive-mount" (chk (lib.hasInfix " ${m0.remote} ${m0.mountPoint} " (toString rcloneUnit.Service.ExecStart) && !(hm.systemd.user.services ? school-onedrive-mount) && !(baseHm.systemd.user.services ? rclone-mount-school-onedrive)) "unit wiring differs: ${toString rcloneUnit.Service.ExecStart}") ]

    [ "school-claude-sync: --delete only on the managed skills, agents and commands dirs" (chk (countOf "--delete" syncText == 1 && lib.hasInfix "for d in skills agents commands; do" syncText && lib.hasInfix "--delete --chown=${userName}:${c.users.users.${userName}.group} \"$src/.claude/$d/\" \"$dst/.claude/$d/\"" syncText && !(lib.hasInfix "rm " syncText)) "unexpected --delete use or rm in the sync script") ]
    [ "school-claude-sync: source is the base user's dotfiles-private claude/school, destination the school home, exits 0 when the source is missing" (chk (lib.hasInfix "src=${baseHome}/dotfiles-private/claude/school\n" syncText && lib.hasInfix "dst=${home}\n" syncText && countOf "${baseHome}/" syncText == 1 && lib.hasInfix "if [ ! -d \"$src\" ]; then" syncText && lib.hasInfix "exit 0\nfi" syncText && lib.hasSuffix "exit 0\n" syncText) "paths or the missing-source exit differ") ]
    [ "school-claude-sync is a oneshot wanted by multi-user.target and absent from the base (control)" (chk (sync.serviceConfig.Type == "oneshot" && lib.elem "multi-user.target" sync.wantedBy && !(base.systemd.services ? school-claude-sync)) "service wiring differs or the base has it") ]
    [ "school-dotfiles-sync and school-nix-sync: user oneshot, Restart=on-failure, wanted by default.target, no start limit, no ConditionPathExists, absent from the base (control)" (chk (lib.all (n: let u = hm.systemd.user.services.${n}; in u.Service.Type == "oneshot" && u.Service.Restart == "on-failure" && u.Unit.StartLimitIntervalSec == 0 && lib.elem "default.target" u.Install.WantedBy && !(u.Unit ? ConditionPathExists) && !(baseHm.systemd.user.services ? ${n})) [ "school-dotfiles-sync" "school-nix-sync" ]) "unit wiring differs or the base has one of them") ]
    [ "school-dotfiles-clone is gone: replaced by school-dotfiles-sync in the spec and absent from the base (control)" (chk (!(hm.systemd.user.services ? school-dotfiles-clone) && !(baseHm.systemd.user.services ? school-dotfiles-clone) && hm.systemd.user.services ? school-dotfiles-sync) "the old unit still exists or the new one is missing") ]
    [ "school-nix-sync: the sync target ~/<flakeDir> in the school home is the directory the direnv use_dev_env/use_combined_env helpers resolve dev-environments from" (chk (lib.hasInfix "use flake ${syncTarget}/templates/krit/dev-environments/language-specific/$1" devEnvStdlib && lib.hasInfix "use flake ${syncTarget}/templates/krit/dev-environments/language-combined/$1" devEnvStdlib && syncTarget != "${home}/") "direnv stdlib: ${devEnvStdlib}") ]
    [ "ext-dotfiles-private is off in the spec and its claude/school links are gone from the school user's home" (chk (c.myconfig.services.external.dotfiles-private.enable == false && !(lib.any (lib.hasPrefix ".claude/") (lib.attrNames hm.home.file)) && !(anyNeedle "dotfiles-private" (map (n: toString hm.home.file.${n}.source) (lib.attrNames hm.home.file)))) "private dotfiles links remain in the school home") ]

    [ "setup: the RPM is resolved once on the host and handed to the container as ONE quoted argument; no compgen lookup left" (chk (hostArgSites == 1 && countOf "school-sqldeveloper-rpm-resolve" setupText == 1 && lib.hasInfix "[ -n \"$1\" ] || exit 1" setupText && lib.hasInfix "sudo bsdtar -xf \"$1\" -C /" setupText && !(lib.hasInfix "compgen" setupText) && !(lib.hasInfix "compgen" checkText)) "host argument sites ${toString hostArgSites}") ]
    [ "setup: resolve, then stage (school-stage-file, once), then HOST_ARG becomes the staged copy, then the container install runs with \"$HOST_ARG\"; a stage failure counts as FAILED" (chk (lib.all (i: i >= 0) stageIdx && stageIdx == lib.sort (a: b: a < b) stageIdx && countOf "school-stage-file" setupText == 1 && lib.hasInfix "STAGED_FILE=$(" setupText && lib.hasInfix "if [ \"$stage_rc\" -ne 0 ]; then" setupText && lib.hasInfix "FAILED to stage the installer for oracle-sqldeveloper" setupText) "marker positions ${toString stageIdx}") ]
    [ "setup: cleanup_staged exists once, runs on EXIT (trap) and after the install, and removes only a plain staged file (-f, not -L) plus an empty stage directory (rmdir, never rm -r)" (chk (cleanupFn != "" && countOf "cleanup_staged() {" setupText == 1 && lib.hasInfix "trap cleanup_staged EXIT" setupText && lib.hasInfix "trap 'exit 130' INT" setupText && lib.hasInfix "trap 'exit 143' TERM" setupText && countOf "cleanup_staged\n" setupText >= 1 && lib.hasInfix "[ -n \"$STAGED_FILE\" ] && [ -f \"$STAGED_FILE\" ] && [ ! -L \"$STAGED_FILE\" ]" cleanupFn && lib.hasInfix "rm -f -- \"$STAGED_FILE\"" cleanupFn && lib.hasInfix "rmdir -- " cleanupFn && !(lib.hasInfix "rm -r" cleanupFn) && !(lib.hasInfix "HOST_ARG" cleanupFn)) "cleanup_staged body: ${cleanupFn}") ]
    [ "setup: exit 10 of the resolver is BLOCKED (message, exit 3), other non-zero codes FAILED (exit 1), failures take precedence" (chk (lib.hasInfix "\"$host_rc\" -eq 10" setupText && lib.hasInfix "Cannot install oracle-sqldeveloper: OpenCloud is not mounted, nothing was installed." setupText && lib.hasInfix "BLOCKED=$((BLOCKED + 1))" setupText && lib.hasInfix "exit 3" setupText && lib.hasInfix "elif [ \"$host_rc\" -ne 0 ]; then" setupText && (lib.length (lib.splitString "exit 1" (lib.head (lib.splitString "exit 3" setupText))) > 1)) "blocked/failed branches differ") ]
  ];

  schoolGroup = c.users.users.${userName}.group;
  ruleTok = r: n: lib.elemAt (lib.filter (t: t != "") (lib.splitString " " r) ++ [ "" "" "" "" "" ]) n;
  ruleType = r: let m = builtins.match "([A-Za-z]+)[-+!=~^]*" (ruleTok r 0); in if m == null then ruleTok r 0 else lib.head m;
  rulePath = r: ruleTok r 1;
  destructiveTypes = [ "Z" "R" "r" "z" "x" "X" "D" ];
  touchesHome = p: p == home || lib.hasPrefix "${home}/" p || lib.hasPrefix "${lib.removeSuffix "/" p}/" home || builtins.match ".*[*?\\[%].*" p != null;
  destructiveOnHome = rules: lib.filter (r: lib.elem (ruleType r) destructiveTypes && touchesHome (rulePath r)) rules;
  homeRuleOk = rules: u:
    let atHome = lib.filter (r: rulePath r == home) rules;
    in u.homeMode != "" && u.home == home && lib.length atHome == 1
      && (let r = lib.head atHome; in ruleTok r 0 == "d" && ruleTok r 2 == u.homeMode && ruleTok r 3 == userName && ruleTok r 4 == u.group);
  homeLevelRules = rules: lib.filter (r: lib.hasPrefix "/home/" (rulePath r)) rules;
  homeIsParent = rules: let rs = homeLevelRules rules; in lib.length rs > 1 && lib.any (r: rulePath r == home) rs && lib.all (r: rulePath r == home || lib.hasPrefix "${home}/" (rulePath r)) rs;
  homeFsOk = fs: fs ? "/home" && fs."/home".fsType != "tmpfs" && fs."/home".neededForBoot && lib.hasPrefix "/home/" home;

  realRules = c.systemd.tmpfiles.rules;
  homeRuleLine = "d ${home} ${c.users.users.${userName}.homeMode} ${userName} ${schoolGroup} -";
  mutCfg = m:
    let s = (flake.nixosConfigurations.${host}.extendModules { modules = [{ specialisation.school.configuration = m; }]; }).config.specialisation.school.configuration;
    in s.config or s;
  mutRules = f: { systemd.tmpfiles.rules = lib.mkOverride 40 (f realRules); };
  mOwner = mutCfg (mutRules (map (r: if rulePath r == home then "d ${home} 0755 root root -" else r)));
  mDestruct = mutCfg (mutRules (rs: rs ++ [ "Z ${home}/opencloud 0700 ${userName} ${schoolGroup} -" ]));
  mOutside = mutCfg (mutRules (rs: rs ++ [ "d /home/other-user/x 0700 ${userName} ${schoolGroup} -" ]));
  mNoBoot = mutCfg { fileSystems."/home".neededForBoot = lib.mkOverride 40 false; };

  homeRuleChecks = [
    [ "tmpfiles: exactly one rule on the school home, type d, mode = the user's homeMode, owner = school user, group = the user's primary group" (chk (homeRuleOk realRules c.users.users.${userName}) "home rule wrong or not unique among: ${toString (lib.filter (r: lib.hasInfix home r) realRules)}") ]
    [
      "control: the home rule probe rejects root ownership (real mutant), a duplicate, a wrong mode, a wrong group, a wrong type and a missing rule"
      (chk
        (
          realRules != [ ] && homeRuleOk realRules c.users.users.${userName}
          && !(homeRuleOk mOwner.systemd.tmpfiles.rules mOwner.users.users.${userName})
          && !(homeRuleOk (realRules ++ [ homeRuleLine ]) c.users.users.${userName})
          && !(homeRuleOk [ "d ${home} 0755 ${userName} ${schoolGroup} -" ] c.users.users.${userName})
          && !(homeRuleOk [ "d ${home} ${c.users.users.${userName}.homeMode} ${userName} root -" ] c.users.users.${userName})
          && !(homeRuleOk [ "Z ${home} ${c.users.users.${userName}.homeMode} ${userName} ${schoolGroup} -" ] c.users.users.${userName})
          && !(homeRuleOk (lib.filter (r: rulePath r != home) realRules) c.users.users.${userName})
        ) "home rule probe accepts a broken rule")
    ]
    [ "tmpfiles: no recursive or destructive rule (Z R r z x X D) on the school home, below it, or on a parent or glob that covers it" (chk (destructiveOnHome realRules == [ ]) "destructive rules: ${toString (destructiveOnHome realRules)}") ]
    [ "control: other modules do have destructive-type rules elsewhere, so the type probe and the path scope both matter" (chk (lib.any (r: lib.elem (ruleType r) destructiveTypes) realRules && destructiveOnHome realRules == [ ]) "no destructive rule exists anywhere, the type probe is unproven") ]
    [
      "control: the destructive probe flags a real Z mutant under ~/opencloud and every destructive type on the home, ~/opencloud/University, ~/oneDrive, /home, / and a glob, but not d"
      (chk
        (
          destructiveOnHome mDestruct.systemd.tmpfiles.rules != [ ]
          && lib.all (t: lib.all (p: destructiveOnHome [ "${t} ${p} - - - -" ] != [ ]) [ home "${home}/opencloud/University" "${home}/oneDrive" "/home" "/" "/home/*" ]) destructiveTypes
          && lib.all (t: destructiveOnHome [ "${t}! ${home}/opencloud - - - -" ] != [ ]) [ "R" "Z" ]
          && destructiveOnHome [ "d ${home}/opencloud 0700 ${userName} ${schoolGroup} -" "R! /etc/passwd.lock - - - - -" "r /lib/x - - - - -" ] == [ ]
        ) "destructive probe misses a rule or flags a harmless one")
    ]
    [ "tmpfiles: the school home rule is the parent of every other /home rule (oneDrive, opencloud, University, .ssh)" (chk (homeIsParent realRules) "/home rules: ${toString (homeLevelRules realRules)}") ]
    [
      "control: the parent probe rejects a /home rule outside the school home (real mutant), a missing home rule and a lone home rule"
      (chk
        (
          homeIsParent realRules
          && !(homeIsParent mOutside.systemd.tmpfiles.rules)
          && !(homeIsParent (lib.filter (r: rulePath r != home) realRules))
          && !(homeIsParent [ homeRuleLine ])
        ) "parent probe accepts a foreign or missing home rule")
    ]
    [ "/home is a separate non-tmpfs filesystem with neededForBoot in the spec and the school home lives under it" (chk (homeFsOk c.fileSystems) "fileSystems./home: ${builtins.toJSON { inherit (c.fileSystems."/home" or { }) fsType neededForBoot; }}") ]
    [
      "control: the /home probe rejects a real neededForBoot=false mutant, a tmpfs /home and a missing /home"
      (chk
        (
          homeFsOk c.fileSystems
          && !(homeFsOk mNoBoot.fileSystems)
          && !(homeFsOk { "/home" = { fsType = "tmpfs"; neededForBoot = true; }; })
          && !(homeFsOk { })
        ) "/home probe accepts a broken mount")
    ]
  ];

  lsPort = 53317;
  pnames = ps: map lib.getName ps;
  lsState = cfg: {
    opt = cfg.myconfig.services.localsend.enable;
    prog = cfg.programs.localsend.enable;
    pkg = lib.elem "localsend" (pnames cfg.environment.systemPackages);
    tcp = lib.elem lsPort cfg.networking.firewall.allowedTCPPorts;
    udp = lib.elem lsPort cfg.networking.firewall.allowedUDPPorts;
  };
  lsOn = cfg: lib.all (v: v) (lib.attrValues (lsState cfg));
  lsOff = cfg: lib.all (v: !v) (lib.attrValues (lsState cfg));
  confOf = sp: sp.config or sp;
  otherSpecs = lib.genAttrs [ "guest" "secure-travel" ] (n: confOf base.specialisation.${n}.configuration);
  mNoLs = mutCfg { myconfig.services.localsend.enable = lib.mkOverride 40 false; };

  pinsOf = cfg: cfg.myconfig.programs.kde.pinnedApps;
  schoolPins = pinsOf c;
  basePins = pinsOf base;
  pkgDesktopIds = {
    ${c.myconfig.constants.terminal.name} = "${c.myconfig.constants.terminal.name}.desktop";
    ${c.myconfig.constants.browser} = "${c.myconfig.constants.browser}.desktop";
    obs-studio = "com.obsproject.Studio.desktop";
    localsend = "LocalSend.desktop";
    ${lib.getName sysPkgs.vscode} = "code.desktop";
    ${lib.getName sysPkgs.intellij-idea} = "intellij-idea.desktop";
  };
  expectedPins = [
    "${c.myconfig.constants.browser}.desktop"
    "${c.myconfig.constants.terminal.name}.desktop"
    "yazi.desktop"
    "custom-nvim.desktop"
    "school-pwa-icorsi.desktop"
    "school-pwa-supsi-portal.desktop"
    "code.desktop"
    "intellij-idea.desktop"
    "com.obsproject.Studio.desktop"
    "LocalSend.desktop"
  ];
  availableIds = idMap: cfg:
    let
      h = cfg.home-manager.users.${cfg.myconfig.constants.user};
      have = pnames (h.home.packages ++ cfg.environment.systemPackages);
    in
    lib.unique (
      map (n: "${n}.desktop") (lib.attrNames h.xdg.desktopEntries)
      ++ lib.filter (lib.hasSuffix ".desktop") (map (p: p.name or "") h.home.packages)
      ++ lib.concatMap (n: lib.optional (lib.elem n have) idMap.${n}) (lib.attrNames idMap)
    );
  unresolved = idMap: cfg: pins: lib.subtractLists (availableIds idMap cfg) pins;
  droppedBasePins = unresolved pkgDesktopIds c basePins;
  mPins = mutCfg { myconfig.programs.kde.pinnedApps = lib.mkOverride 40 (schoolPins ++ [ "github-desktop.desktop" "does-not-exist.desktop" ]); };

  keyList = e: if builtins.isList e.on then e.on else [ e.on ];
  mgrKm = h: h.programs.yazi.keymap.mgr.prepend_keymap or [ ];
  goChords = h: lib.filter (e: lib.length (keyList e) == 2 && lib.head (keyList e) == "g") (mgrKm h);
  goKeys = h: map (e: lib.elemAt (keyList e) 1) (goChords h);
  goRun = h: k: (lib.findFirst (e: lib.elemAt (keyList e) 1 == k) { run = null; } (goChords h)).run;
  sorted = lib.sort (a: b: a < b);
  schoolGoKeys = [ "c" "d" "D" "p" "v" "." "t" "M" "o" "O" "P" "y" "T" "S" ];
  droppedGoKeys = [ "n" "m" ];
  keptGoKeys = [ "c" "d" "D" "p" "v" "." "t" "M" ];
  flakeDir = c.myconfig.constants.flakeDir;
  goTargets = lib.filter (r: r != null) (map (k: goRun hm k) (goKeys hm));

  yaziChecks = [
    [ "yazi go-to chords: the school set is exactly gc gd gD gp gv g. gt gM plus go gO gP gy gT gS" (chk (mgrKm hm != [ ] && sorted (goKeys hm) == sorted schoolGoKeys) "go-to keys: ${toString (sorted (goKeys hm))}") ]
    [ "yazi go-to chords: gn and gm are gone and no go-to target mentions /mnt, ~/<flakeDir> or dev-environments" (chk (lib.all (k: !(lib.elem k (goKeys hm))) droppedGoKeys && goTargets != [ ] && lib.all (r: !(lib.hasInfix "/mnt" r) && !(lib.hasInfix "~/${flakeDir}" r) && !(lib.hasInfix "dev-environments" r)) goTargets) "go-to targets: ${toString goTargets}") ]
    [ "yazi go-to chords: the added ones point at the school layout (gP ~/Projects, go ~/opencloud, gO ~/oneDrive, gy ~/Documents/year, gT ~/Templates, gS ~/Public)" (chk (goRun hm "P" == "cd ~/Projects" && goRun hm "o" == "cd ~/opencloud" && goRun hm "O" == "cd ~/oneDrive" && goRun hm "y" == "cd ~/Documents/year" && goRun hm "T" == "cd ~/Templates" && goRun hm "S" == "cd ~/Public") "runs: P=${toString (goRun hm "P")} o=${toString (goRun hm "o")} O=${toString (goRun hm "O")} y=${toString (goRun hm "y")} T=${toString (goRun hm "T")} S=${toString (goRun hm "S")}") ]
    [ "yazi go-to chords are consistent with the rest of the spec: opencloud and oneDrive are the mount parents, Documents/year is created, Projects/Templates/Public are xdg user dirs" (chk (lib.any (r: lib.hasPrefix "d ${home}/opencloud " r) c.systemd.tmpfiles.rules && m0.mountPoint == "${home}/oneDrive" && lib.hasInfix "\"$HOME/Documents/year/" createDirs && lib.hasInfix "XDG_PROJECTS_DIR=\"${home}/Projects\"" userDirsFile && lib.hasInfix "XDG_TEMPLATES_DIR=\"${home}/Templates\"" userDirsFile && lib.hasInfix "XDG_PUBLICSHARE_DIR=\"${home}/Public\"" userDirsFile) "targets are not backed by the spec: mount ${m0.mountPoint}, user-dirs ${userDirsFile}") ]
    [ "yazi go-to chords: the kept ones run the same command as in the base (exclusions do not alter the defaults)" (chk (lib.all (k: goRun hm k == goRun baseHm k && goRun hm k != null) keptGoKeys) "kept chords differ from the base: ${toString (lib.filter (k: goRun hm k != goRun baseHm k) keptGoKeys)}") ]
    [ "yazi go-to chords are unique in the final keymap (an extra never shadows a default)" (chk (lib.length (goKeys hm) == lib.length (lib.unique (goKeys hm))) "duplicate go-to keys: ${toString (goKeys hm)}") ]
    [ "control: the base keymap still has gn, gm and a gP that points into dev-environments (the exclusions and the gP replacement bite)" (chk (lib.all (k: lib.elem k (goKeys baseHm)) [ "n" "m" "P" ] && lib.hasInfix "dev-environments" (goRun baseHm "P") && lib.hasInfix "~/${flakeDir}" (goRun baseHm "n")) "base go-to keys: ${toString (goKeys baseHm)}") ]
  ];

  claudeChecks = [
    [ "claude-code-wrappers connectorWorkspaces is [ \"\" ] in the spec (the whole home) and the cai script allows Calendar and Gmail at $h" (chk (c.myconfig.krit.programs.claude-code-wrappers.connectorWorkspaces == [ "" ] && lib.hasInfix "\"claude.ai Google Calendar\": [$h, $h + \"/momentary\"" caiText && lib.hasInfix "\"claude.ai Gmail\": [$h, $h + \"/momentary\"" caiText) "connectorWorkspaces ${builtins.toJSON c.myconfig.krit.programs.claude-code-wrappers.connectorWorkspaces}") ]
    [ "control: the base config keeps the NixOS default (no school workspace allowed) in its cai script" (chk (base.myconfig.krit.programs.claude-code-wrappers.connectorWorkspaces == [ ] && caiTextOf base != "" && !(lib.hasInfix "[$h," (caiTextOf base)) && lib.hasInfix "\"claude.ai Gmail\": [$h + \"/momentary\"" (caiTextOf base)) "base connectorWorkspaces ${builtins.toJSON base.myconfig.krit.programs.claude-code-wrappers.connectorWorkspaces}") ]
  ];

  localsendChecks = [
    [ "localsend: myconfig.services.localsend and programs.localsend are on in the spec, the localsend package is installed and the firewall opens ${toString lsPort} for TCP and UDP" (chk (lsOn c) "state ${builtins.toJSON (lsState c)}") ]
    [ "control: the base host also reads localsend fully on (the on-probe accepts a real enabled host)" (chk (lsOn base) "base state ${builtins.toJSON (lsState base)}") ]
    [ "control: a real mutant with myconfig.services.localsend off reads as fully off (option, programs, package, TCP and UDP port) and fails the on-probe" (chk (lsOff mNoLs && !(lsOn mNoLs)) "mutant state ${builtins.toJSON (lsState mNoLs)}") ]
    [ "guest and secure-travel keep localsend fully off (option, programs, package, TCP and UDP port) while the school spec and the base read on (the off-probe bites)" (chk (lib.all lsOff (lib.attrValues otherSpecs) && lsOn c && lsOn base) "guest ${builtins.toJSON (lsState otherSpecs.guest)}, secure-travel ${builtins.toJSON (lsState otherSpecs."secure-travel")}") ]
  ];

  pinChecks = [
    [ "kde pins: the school spec pins a non-empty, duplicate-free list that differs from the base host list" (chk (schoolPins != [ ] && schoolPins == lib.unique schoolPins && schoolPins != basePins && basePins != [ ]) "school pins ${toString schoolPins}, base pins ${toString basePins}") ]
    [ "kde pins: exactly browser, terminal, yazi, custom-nvim, the iCorsi and SUPSI Portal PWAs, code, intellij-idea, OBS and LocalSend, in this order" (chk (schoolPins == expectedPins) "pins ${toString schoolPins}") ]
    [ "kde pins: the browser and terminal constants are pinned as <constant>.desktop" (chk (lib.elem "${c.myconfig.constants.browser}.desktop" schoolPins && lib.elem "${c.myconfig.constants.terminal.name}.desktop" schoolPins) "constants ${c.myconfig.constants.browser}/${c.myconfig.constants.terminal.name} not in pins ${toString schoolPins}") ]
    [ "kde pins: every pinned desktop id resolves in the school generation (HM desktopEntries, makeDesktopItem packages, or a mapped package that is installed)" (chk (unresolved pkgDesktopIds c schoolPins == [ ]) "unresolved pins: ${toString (unresolved pkgDesktopIds c schoolPins)}") ]
    [ "kde pins: no base pin that the school generation cannot resolve is still pinned" (chk (droppedBasePins != [ ] && lib.all (p: !(lib.elem p schoolPins)) droppedBasePins) "dropped base pins ${toString droppedBasePins}, still pinned: ${toString (lib.filter (p: lib.elem p schoolPins) droppedBasePins)}") ]
    [ "control: the base pins hold ids the school generation lacks, and a real mutant adding github-desktop.desktop and does-not-exist.desktop leaves exactly those two unresolved" (chk (droppedBasePins != [ ] && unresolved pkgDesktopIds mPins (pinsOf mPins) == [ "github-desktop.desktop" "does-not-exist.desktop" ]) "dropped ${toString droppedBasePins}, mutant unresolved ${toString (unresolved pkgDesktopIds mPins (pinsOf mPins))}") ]
    [ "control: without the package map the terminal, browser, OBS, LocalSend, VS Code and IntelliJ ids are unresolved (the map is load-bearing, entries and items do not over-accept)" (chk (lib.sort (a: b: a < b) (unresolved { } c schoolPins) == lib.sort (a: b: a < b) (lib.filter (p: lib.elem p (lib.attrValues pkgDesktopIds)) schoolPins) && unresolved { } c schoolPins != [ ]) "unresolved without map: ${toString (unresolved { } c schoolPins)}") ]
    [ "control: LocalSend.desktop stops resolving when the localsend package is gone (real mutant with localsend off keeps the pin)" (chk (lib.elem "LocalSend.desktop" (pinsOf mNoLs) && unresolved pkgDesktopIds mNoLs (pinsOf mNoLs) == [ "LocalSend.desktop" ]) "mutant unresolved ${toString (unresolved pkgDesktopIds mNoLs (pinsOf mNoLs))}") ]
  ];

  printingChecks =
    [
      [ "control: myconfig.constants.hostname equals the evaluated host, so the laptop gate cannot misclassify a host" (chk (c.myconfig.constants.hostname == host && isLaptop == (host == "nixos-laptop")) "constants.hostname is ${c.myconfig.constants.hostname}, evaluated host is ${host}") ]
      [ "control: the printing probe reports etc, service and secret names that exist in the spec (probe bites)" (chk ((c.services.printing ? enable) && lib.subtractLists [ "cups" ] (printingProbe c knownNames) == [ "etc" "service" "secret" ]) "probe misses names that exist: ${toString (printingProbe c knownNames)}") ]
    ]
    ++ lib.optionals isLaptop [
      [ "SUPSI printing: cups on, smb.conf has SMB2" (chk (c.services.printing.enable && lib.hasInfix "client min protocol = SMB2" c.environment.etc."samba/smb.conf".text) "printing off or smb.conf lacks SMB2") ]
      [ "SUPSI printing: oneshot after cups, ExecStart is a store script without embedded credentials" (chk (c.services.printing.enable && (c.systemd.services ? supsi-printer-setup) && c.systemd.services.supsi-printer-setup.serviceConfig.Type == "oneshot" && lib.elem "cups.service" c.systemd.services.supsi-printer-setup.after && lib.hasPrefix "/nix/store/" (toString c.systemd.services.supsi-printer-setup.serviceConfig.ExecStart) && !(lib.hasInfix "smb://" (toString c.systemd.services.supsi-printer-setup.serviceConfig.ExecStart))) "printing service missing, not a oneshot after cups, or ExecStart not a plain store script") ]
      [ "SUPSI printing: smb.conf has client min protocol = SMB2, password secret is root 0400 and school-only" (chk (lib.hasInfix "client min protocol = SMB2" c.environment.etc."samba/smb.conf".text && (c.sops.secrets.school_supsi_password.mode == "0400" && c.sops.secrets.school_supsi_password.owner == "root") && !(base.sops.secrets ? school_supsi_password) && !(base.systemd.services ? supsi-printer-setup)) "smb.conf lacks SMB2, secret mode/owner differs, or the printing wiring leaks into the base config") ]
    ]
    ++ lib.optionals (!isLaptop) [
      [ "SUPSI printing is laptop-only: the spec adds no cups of its own (inherited from the base is fine), smb.conf, supsi-printer-setup or school_supsi_password, and the base has no school printing service or secret" (chk (lib.subtractLists (lib.optional (base.services.printing.enable or false) "cups") (printingProbe c printingNames) == [ ] && !(base.systemd.services ? supsi-printer-setup) && !(base.sops.secrets ? school_supsi_password)) "printing wiring present on a non-laptop host: ${toString (printingProbe c printingNames)}") ]
    ];

  caiTextOf = cfg: let p = lib.findFirst (p: (p.name or "") == "cai") null cfg.environment.systemPackages; in if p == null then "" else p.text or "";
  caiText = caiTextOf c;

  checks = [
    [ "specialisation.school evaluates for ${host}" (chk (base.specialisation ? school && c.system.nixos.tags == [ "school" ]) "specialisation.school missing or tags differ") ]
    [ "constants.shell == bash" (chk (c.myconfig.constants.shell == "bash") "shell is ${c.myconfig.constants.shell}") ]
    [ "myconfig.services.tailscale.enable" (chk c.myconfig.services.tailscale.enable "tailscale not forced on") ]
    [ "systemd.services has upstream tailscaled-autoconnect, not the removed tailscale-autoconnect" (chk (c.systemd.services ? tailscaled-autoconnect && !(c.systemd.services ? tailscale-autoconnect)) "tailscaled-autoconnect absent or removed tailscale-autoconnect is back") ]
    [ "exit-node-off wantedBy multi-user.target" (chk (unit != null && unit.wantedBy == [ "multi-user.target" ]) "unit missing or wantedBy differs") ]
    [ "exit-node-off after/wants units exist" (chk (unitDeps != [ ] && lib.all serviceExists unitDeps) "unknown units: ${toString (lib.filter (u: !serviceExists u) unitDeps)}") ]
    [ "exit-node-off After tailscaled, not the removed tailscale-autoconnect" (chk (unit != null && lib.elem "tailscaled.service" unit.after && !(lib.elem "tailscale-autoconnect.service" unitDeps)) "not After tailscaled.service or still references tailscale-autoconnect.service") ]
    [ "exit-node-off is non-blocking (Type=exec)" (chk (unit != null && (unit.serviceConfig.Type or "") == "exec") "Type is ${if unit == null then "missing" else unit.serviceConfig.Type or "unset"}") ]
    [ "exit-node-off retries tailscale set --exit-node= in a bounded timeout loop" (chk (unit != null && lib.hasInfix "seq 1 " unit.script && lib.hasInfix "timeout " unit.script && lib.hasInfix "tailscale set --exit-node= && exit 0" unit.script && lib.hasInfix "exit 1" unit.script && !(lib.hasInfix "BackendState" unit.script)) "script lacks bounded retry of the set, or still waits on BackendState") ]
    [ "exit-node-off has tailscale on its path" (chk (unit != null && lib.any (p: lib.hasPrefix "tailscale" (p.name or "")) unit.path) "tailscale package missing from unit path") ]

    [ "ssh enableDefaultConfig is off" (chk (hm.programs.ssh.enableDefaultConfig == false) "default ssh config re-enabled") ]
    [ "ssh IdentityFile is the sops school key for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentityFile or "") == idFile) == [ ]) "wrong IdentityFile for: ${toString (sshBad (s: (s.IdentityFile or "") == idFile))}") ]
    [ "ssh IdentitiesOnly == yes for github, gitlab, supsi gitlab" (chk (sshBad (s: (s.IdentitiesOnly or "") == "yes") == [ ]) "IdentitiesOnly not yes for: ${toString (sshBad (s: (s.IdentitiesOnly or "") == "yes"))}") ]
    [ "ssh github.com entry is exactly Hostname github.com, IdentityFile <school home>/.ssh/id_school and IdentitiesOnly yes" (chk (removeAttrs (sshOf hm "github.com") [ "header" ] == { Hostname = "github.com"; IdentityFile = "${home}/.ssh/id_school"; IdentitiesOnly = "yes"; }) "github.com entry is ${builtins.toJSON (sshOf hm "github.com")}") ]
    [ "system-wide github.com host key pin: an ssh-ed25519 key in programs.ssh.knownHosts, rendered into /etc/ssh/ssh_known_hosts" (chk (githubPin != null && lib.hasPrefix "ssh-ed25519 " githubPin && builtins.length (lib.splitString " " githubPin) == 2 && lib.hasInfix "github.com ${githubPin}\n" (c.environment.etc."ssh/ssh_known_hosts".text or "")) "pin ${builtins.toJSON githubPin}; known_hosts text: ${c.environment.etc."ssh/ssh_known_hosts".text or "absent"}") ]
    [ "control: the base config has no github.com host key pin and its known_hosts text does not render one (the pin probe bites)" (chk (!(base.programs.ssh.knownHosts ? "github.com") && !(lib.hasInfix "github.com " (base.environment.etc."ssh/ssh_known_hosts".text or ""))) "the base config already pins github.com") ]
    [ "school github identity differs from the base host identity" (chk (sshOf baseHm "github.com" ? IdentityFile && (sshOf baseHm "github.com").IdentityFile != (sshOf hm "github.com").IdentityFile) "base and school share the github IdentityFile (or base has none)") ]

    [ "git user.email is school-specific and not the base email" (chk (gitSet.user.email != baseHm.programs.git.settings.user.email && gitSet.user.email != "") "school email equals base email") ]
    [ "git gpg.format == ssh and commit signing on" (chk (gitSet.gpg.format == "ssh" && hm.programs.git.signing.signByDefault && (gitSet.commit.gpgSign or false)) "ssh signing not fully enabled") ]
    [ "git signByDefault also signs tags" (chk ((hm.programs.git.iniContent.tag.gpgSign or false) == true) "tag.gpgSign is not true") ]
    [ "git signing key is user.signingKey == sops school key" (chk ((gitSet.user.signingKey or "") == idFile) "user.signingKey is '${gitSet.user.signingKey or "unset"}', expected ${idFile}") ]
    [ "no lowercase user.signingkey and no signing.key (single source: git-ssh-signing)" (chk (!(gitSet.user ? signingkey) && hm.programs.git.signing.key == null) "lowercase signingkey or signing.key is set again") ]
    [ "git-ssh-signing options carry the school key and school identity" (chk (c.myconfig.krit.system.git-ssh-signing.signingKey == idFile && c.myconfig.krit.system.git-ssh-signing.allowedSignersEmail == gitSet.user.email && c.myconfig.krit.system.git-ssh-signing.allowedSignersEmail != base.myconfig.krit.system.git-ssh-signing.allowedSignersEmail) "option values differ from the school identity") ]
    [ "allowedSignersFile == path of home.file allowed_signers" (chk (gitSet.gpg.ssh.allowedSignersFile == "${home}/${signers.target}") "${gitSet.gpg.ssh.allowedSignersFile} vs ${home}/${signers.target}") ]
    [ "allowed_signers first line == git user.email, ed25519 key" (chk (lib.length signerFields >= 3 && lib.elemAt signerFields 0 == gitSet.user.email && lib.elemAt signerFields 1 == "ssh-ed25519") "signers line does not match git identity") ]
    [ "allowed_signers has exactly ONE line (the school principal) and extraAllowedSigners is empty" (chk (lib.length signerLines == 1 && principalOf (lib.head signerLines) == gitSet.user.email && c.myconfig.krit.system.git-ssh-signing.extraAllowedSigners == [ ]) "lines: ${toString (lib.length signerLines)}; extraAllowedSigners: ${builtins.toJSON c.myconfig.krit.system.git-ssh-signing.extraAllowedSigners}") ]
    [ "allowed_signers names no personal signer: neither the base principal, nor its key, nor the nicolkrit999 handle" (chk (lib.all (l: !(lib.hasInfix l signers.text) && !(lib.hasInfix (lib.elemAt (lib.splitString " " l) 2) signers.text) && !(lib.hasInfix (principalOf l) signers.text)) baseSignerLines && !(lib.hasInfix "nicolkrit999" signers.text)) "the school allowed_signers still carries a personal signer: ${signers.text}") ]
    [ "control: base allowed_signers does not name the school principal, but does name its own personal principal (the signer probes bite)" (chk (!(lib.any (l: principalOf l == gitSet.user.email) baseSignerLines) && baseSignerLines != [ ] && lib.all (l: principalOf l != gitSet.user.email && lib.hasInfix (principalOf l) baseHm.home.file.".ssh/allowed_signers".text) baseSignerLines) "base signers already contain the school principal or are empty") ]

    [ "school secrets are declared inside the specialisation, ssh pub next to the key" (chk (c.sops.secrets ? school_ssh_key && c.sops.secrets ? school_ssh_pub && c.sops.secrets.school_ssh_pub.path == "${idFile}.pub") "school_ssh_key/school_ssh_pub missing in the spec or pub path differs") ]
    [ "school secrets are absent from the base config (control)" (chk (!(base.sops.secrets ? school_ssh_key) && !(base.sops.secrets ? school_ssh_pub)) "base config declares the school secrets") ]

    [ "NetworkManager VPN plugins openvpn and openconnect are registered in the spec" (chk (c.environment.etc ? "NetworkManager/VPN/nm-openvpn-service.name" && c.environment.etc ? "NetworkManager/VPN/nm-openconnect-service.name") "nm-openvpn/nm-openconnect service.name missing from environment.etc") ]
    [ "control: an unrequested NM VPN plugin is not registered (etc probe bites)" (chk (!(c.environment.etc ? "NetworkManager/VPN/nm-nonexistent-service.name")) "etc probe accepts any name") ]
  ] ++ printingChecks ++ [
    [ "wireshark enabled in the spec and the user is in the wireshark group" (chk (c.programs.wireshark.enable && lib.elem "wireshark" c.users.users.${userName}.extraGroups) "wireshark or group membership missing") ]

    [ "school PWA entries exist, have no mimeType and are in category Education" (chk (pwaNames != [ ] && pwaBad pwaOk == [ ]) "bad PWA entries: ${toString (pwaBad pwaOk)} of ${toString pwaNames}") ]
    [ "control: PWA predicate rejects an entry with a mimeType or another category" (chk (pwaOk entries.${lib.head pwaNames} && !(pwaOk (entries.${lib.head pwaNames} // { mimeType = [ "x-scheme-handler/https" ]; })) && !(pwaOk (entries.${lib.head pwaNames} // { categories = [ "Network" "WebBrowser" ]; }))) "PWA predicate accepts a mimeType or a non-Education category") ]

    [ "OneDrive (rcloneMount) user unit has StartLimit settings and no network-online.target ordering" (chk ((onedriveUnit ? StartLimitIntervalSec) && (onedriveUnit ? StartLimitBurst) && !(anyHas "network-online.target" ((lib.toList (onedriveUnit.After or [ ])) ++ (lib.toList (onedriveUnit.Wants or [ ]))))) "StartLimit missing or network-online.target ordering is back") ]
    [ "OneDrive (rcloneMount) unit restarts on failure" (chk (onedrive.Service.Restart == "on-failure") "Restart is ${onedrive.Service.Restart}") ]

    [ "tkgate and sqldeveloper grant X access only to the local user (si:localuser:), never bare xhost +" (chk (lib.all (n: let t = scriptText n; in lib.hasInfix "xhostEntry=\"si:localuser:" t && lib.hasInfix "\"+$xhostEntry\"" t && lib.hasInfix "\"-$xhostEntry\"" t && !(lib.hasInfix "xhost +" t)) [ "tkgate-school" "sqldeveloper-school" ]) "xhost line is not the narrow localuser form with revoke") ]
    [ "no brave-school, vscode-school or idea-school wrapper, desktop item or desktop entry is left in the school home" (chk (leftoverWrappers == [ ] && !(lib.any (n: lib.hasPrefix "brave-school" n || lib.hasPrefix "vscode-school" n || lib.hasPrefix "idea-school" n) (lib.attrNames entries))) "leftover wrappers: ${toString leftoverWrappers}; entries ${toString (lib.attrNames entries)}") ]
    [ "control: the wrapper-name probe finds a real school launcher script (tkgate-school), so the absence check is not vacuous" (chk (lib.any (p: lib.hasPrefix "tkgate-school" (p.name or "")) hm.home.packages) "no tkgate-school package visible to the probe") ]
    [ "plain apps are installed in the school home (no wrappers): brave, vscode, intellij-idea, proton-pass, drawio, pay-respects, tealdeer, teams-for-linux" (chk (missingPlain == [ ]) "not in the school home.packages: ${toString missingPlain}") ]
    [ "control: the installed-app probe rejects a package that the school home does not install (hello)" (chk (!(installedAs sysPkgs.hello) && installedAs sysPkgs.brave) "installedAs accepts hello or rejects brave") ]
    [ "every PWA launches the plain brave package via --app=<url> (no brave-school)" (chk (pwaBad pwaBrave == [ ]) "PWA exec not '<brave>/bin/brave --app=...': ${toString (pwaBad pwaBrave)}") ]
    [ "control: the PWA brave predicate rejects a brave-school exec" (chk (pwaBrave entries.${lib.head pwaNames} && !(pwaBrave (entries.${lib.head pwaNames} // { exec = "brave-school --app=\"https://x\""; }))) "PWA brave predicate accepts brave-school") ]
    [ "iCorsi and SUPSI Portal PWAs use store-path PNG icons (not the missing education theme icon); the others keep theme icon names" (chk (lib.all (n: iconIsStorePng entries.${n}.icon && iconDrvs entries.${n}.icon >= 1) pwaIconNames && lib.all (n: !(lib.hasPrefix "/" entries.${n}.icon)) (lib.filter (n: !(lib.elem n pwaIconNames)) pwaNames)) "icons: ${toString (map (n: "${n}=${entries.${n}.icon}") pwaNames)}") ]
    [ "control: the icon predicate rejects the old theme name education and a path outside the store" (chk (!(iconIsStorePng "education") && !(iconIsStorePng "/usr/share/icons/x.png") && iconIsStorePng entries.school-pwa-icorsi.icon) "icon predicate accepts a theme name or a non-store path") ]
    [ "hyprland autostart opens iCorsi with the plain brave package, not brave-school" (chk (anyHas "${braveBin} --app=https://www.icorsi.ch/" hyprExec && !(anyHas "brave-school" hyprExec)) "autostart: ${toString hyprExec}") ]
    [ "school year directories live in Documents/year (1st..3rd, semesters 1-6), not in the home root; projects is not created by createSchoolDirs" (chk (lib.all (d: lib.hasInfix "\"$HOME/Documents/year/${d}\"" createDirs) yearDirs && !(lib.hasInfix "\"$HOME/year" createDirs) && !(lib.hasInfix "projects" (lib.toLower createDirs)) && !(lib.hasInfix "year/2st" createDirs) && !(lib.hasInfix "year/3st" createDirs)) "createSchoolDirs: ${createDirs}") ]
    [ "xdg.userDirs: Projects, Templates and Public are kept, Music is dropped (no XDG_MUSIC_DIR line and no ~/Music mkdir), Projects is created by the xdg activation" (chk (lib.hasInfix "XDG_PROJECTS_DIR=\"${home}/Projects\"" userDirsFile && lib.hasInfix "XDG_TEMPLATES_DIR=" userDirsFile && lib.hasInfix "XDG_PUBLICSHARE_DIR=" userDirsFile && !(lib.hasInfix "XDG_MUSIC_DIR" userDirsFile) && lib.hasInfix "\"${home}/Projects\"" xdgMkdirs && !(lib.hasInfix "Music" xdgMkdirs)) "user-dirs.dirs: ${userDirsFile}; mkdirs: ${xdgMkdirs}") ]
    [ "control: the base config keeps Music in user-dirs.dirs and its xdg mkdirs (the Music check bites)" (chk (lib.hasInfix "XDG_MUSIC_DIR" baseUserDirsFile && lib.hasInfix "Music" baseXdgMkdirs) "base already drops Music") ]
    [ "removeEmptySchoolLeftovers runs after createSchoolDirs, removes only with a non-recursive rmdir --, over the old ~/year and ~/projects paths, bottom-up" (chk (leftoversOk) "activation: ${leftoversText}") ]
    [ "control: the leftovers probe rejects rm -r, find -delete and a year dir listed before its semester (real order violation)" (chk (!(leftoversOkFor (leftoversText + "\nrm -rf \"$HOME/year\"")) && !(leftoversOkFor (leftoversText + "\nfind \"$HOME\" -delete")) && !(leftoversOkFor (builtins.replaceStrings [ "\"$HOME/year/1st/1-semester\"" "\"$HOME/year\"" ] [ "\"$HOME/year\"" "\"$HOME/year/1st/1-semester\"" ] leftoversText))) "leftovers probe accepts a recursive removal or a wrong order") ]
    [ "no activation script or user tmpfiles rule of the school home removes recursively (rm -r, find -delete, destructive tmpfiles types)" (chk (lib.all (t: !(lib.hasInfix "rm -r" t) && !(lib.hasInfix "rm -fr" t) && !(lib.hasInfix "-delete" t) && !(lib.hasInfix "rm -f" t)) schoolActivationTexts && destructiveOnHome hmTmpfiles == [ ]) "recursive removal in: ${toString (lib.filter (n: let t = hm.home.activation.${n}.data or ""; in lib.hasInfix "rm -r" t || lib.hasInfix "-delete" t) (lib.attrNames hm.home.activation))}") ]
    [ "guiScale is derived from the monitors, not the 1.0 fallback" (chk (lib.length scales == 1 && scale != 1.0 && lib.hasInfix "uiScale=${scaleStr}\"" (scriptText "sqldeveloper-school")) "scale ${scaleStr}, script uiScale ${toString (uiScaleOf (scriptText "sqldeveloper-school"))}") ]

    [ "opencloud spaces are non-empty" (chk (spaces != [ ]) "no spaces to mount") ]
    [ "one school davfs fileSystem per space, davfs type, device == url" (chk (lib.length (lib.attrNames schoolFs) == lib.length spaces && badFs (s: (c.fileSystems.${fsName s} or { }).fsType or "" == "davfs" && c.fileSystems.${fsName s}.device == s.url) == [ ]) "mismatch (fs entries ${toString (lib.length (lib.attrNames schoolFs))} vs spaces ${toString (lib.length spaces)}; bad: ${toString (badFs (s: (c.fileSystems.${fsName s} or { }).fsType or "" == "davfs"))})") ]
    [ "davfs options noauto, nofail, x-systemd.automount, _netdev" (chk (spaces != [ ] && badFs (s: lib.all (o: lib.elem o (optsOf s)) davfsRequired) == [ ]) "missing options for: ${toString (badFs (s: lib.all (o: lib.elem o (optsOf s)) davfsRequired))}") ]
    [ "davfs uid= option equals constants.user" (chk (spaces != [ ] && badFs (s: optEquals "uid" userName (optsOf s)) == [ ]) "uid= is not ${userName} for: ${toString (badFs (s: optEquals "uid" userName (optsOf s)))}; options: ${toString (optsOf (lib.head spaces))}") ]
    [ "davfs gid= option equals the user's primary group name" (chk (spaces != [ ] && badFs (s: optEquals "gid" c.users.users.${userName}.group (optsOf s)) == [ ]) "gid= is not ${c.users.users.${userName}.group} for: ${toString (badFs (s: optEquals "gid" c.users.users.${userName}.group (optsOf s)))}") ]
    [ "davfs2 enabled, secrets file linked, krit in davfs2 group" (chk (c.services.davfs2.enable && c.environment.etc ? "davfs2/secrets" && lib.elem "davfs2" c.users.users.${userName}.extraGroups) "davfs2 wiring incomplete") ]
    [ "no opencloud-desktop sync client next to the davfs mounts (spec and school user)" (chk (!(hasPkgInfix "opencloud-desktop" c.environment.systemPackages) && !(hasPkgInfix "opencloud-desktop" hm.home.packages)) "opencloud-desktop is installed in the school specialisation") ]
    [ "control: the package-name probe finds distrobox in the spec systemPackages and a school script in the user packages" (chk (hasPkgInfix "distrobox" c.environment.systemPackages && hasPkgInfix "tkgate-school" hm.home.packages) "probe cannot see known packages, so the opencloud-desktop absence check is vacuous") ]
    [ "no opencloud space path is exactly University" (chk (!(lib.any (s: s.path == "University") allSpaces)) "a space path collides with the University tmpfiles directory") ]

    [ "sqldeveloper uiScale == hyprland monitor scale, exact render" (chk (lib.length scales == 1 && lib.hasInfix "-Dsun.java2d.uiScale=${scaleStr}\"" (scriptText "sqldeveloper-school")) "monitor scales ${toString scales}; script uiScale ${toString (uiScaleOf (scriptText "sqldeveloper-school"))}") ]
    [ "sqldeveloper uiScale parses to the monitor scale as a float" (chk (lib.length scales == 1 && uiScaleOf (scriptText "sqldeveloper-school") == scale) "parsed ${toString (uiScaleOf (scriptText "sqldeveloper-school"))} vs ${toString scale}") ]
    [ "control: uiScale parser rejects a different scale" (chk (uiScaleOf "-Dsun.java2d.uiScale=${toString (scale + 0.1)}\"" != scale) "parser matches any scale") ]
    [ "tkgate Xft.dpi == floor(96 * monitor scale)" (chk (lib.hasInfix "Xft.dpi: ${toString (builtins.floor (96 * scale))}\"" (scriptText "tkgate-school")) "dpi mismatch for scale ${scaleStr}") ]

    [ "all five school scripts are present and non-empty" (chk (lib.all (n: scriptText n != "") scriptNames) "missing: ${toString (lib.filter (n: scriptText n == "") scriptNames)}") ]
    [ "setup script creates school-ubuntu and school-arch" (chk (lib.hasInfix "--name \"school-ubuntu\"" setup && lib.hasInfix "--name \"school-arch\"" setup) "container names missing in setup") ]
    [ "clear script references both containers" (chk (lib.hasInfix "\"school-ubuntu\"" clear && lib.hasInfix "\"school-arch\"" clear) "container names missing in clear") ]
    [ "tkgate and sqldeveloper launchers enter the matching containers" (chk (lib.hasInfix "enter school-ubuntu" (scriptText "tkgate-school") && lib.hasInfix "enter school-arch" (scriptText "sqldeveloper-school")) "launcher container differs from setup") ]
    [ "every app check is single-quote-safe in the setup script" (chk (checkQuoted == 2) "found ${toString checkQuoted} well-quoted check invocations, expected 2") ]

    [ "hyprland execOnce workspaces are declared in monitorWorkspaces" (chk (execWs != [ ] && lib.all (w: lib.elem w declaredWs) execWs) "undeclared workspaces: ${toString (lib.filter (w: !(lib.elem w declaredWs)) execWs)}") ]
  ] ++ schoolUserChecks ++ homeRuleChecks ++ localsendChecks ++ pinChecks ++ yaziChecks ++ claudeChecks;

  ctxDrvs = suffix: text: lib.filter (d: lib.hasSuffix suffix d) (builtins.attrNames (builtins.getContext text));
  startupDrvs = ctxDrvs "-school-distrobox-startup-check.drv" hm.programs.bash.initExtra;
  deepDrvs = ctxDrvs "-school-distrobox-deep-check.drv" checkText;
  helperDrvs = ctxDrvs "-school-sqldeveloper-rpm-resolve.drv" setupText;
  stageDrvs = ctxDrvs "-school-stage-file.drv" setupText;
  dotfilesSyncDrvs = ctxDrvs "-school-dotfiles-sync.drv" (toString dotfilesUnit.Service.ExecStart);
  nixSyncDrvs = ctxDrvs "-school-nix-sync.drv" (toString nixSyncUnit.Service.ExecStart);
in
{
  report = lib.concatMapStringsSep "\n" (e: "${lib.elemAt e 0}\t${lib.elemAt e 1}") checks + "\n";
  scripts = builtins.toJSON (lib.genAttrs scriptNames scriptText);
  drvs = builtins.toJSON { startup = startupDrvs; deep = deepDrvs; helper = helperDrvs; stage = stageDrvs; dotfilessync = dotfilesSyncDrvs; nixsync = nixSyncDrvs; flakeDir = c.myconfig.constants.flakeDir; mounts = schoolMountNames; leftovers = leftoversText; inherit home; };
  sync = syncText;
}
