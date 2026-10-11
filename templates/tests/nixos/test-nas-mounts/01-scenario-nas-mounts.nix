let host = builtins.getEnv "HOST_UNDER_TEST"; in
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.${host};
  cfg = sys.config;
  my = cfg.myconfig;
  user = my.constants.user;

  check = cond: detail: if cond then "ok" else "FAIL: ${detail}";
  has = x: xs: builtins.elem x xs;
  unique = xs: builtins.length (lib.unique xs) == builtins.length xs;
  fs = cfg.fileSystems;
  fsOf = t: lib.filterAttrs (_: v: v.fsType == t) fs;
  optPrefix = p: opts: lib.findFirst (o: lib.hasPrefix p o) null opts;
  optVal = p: opts: let o = optPrefix p opts; in if o == null then "" else lib.removePrefix p o;

  smb = fsOf "cifs";
  smbNames = builtins.attrNames smb;
  smbDevHosts = lib.unique (map (v: builtins.head (lib.splitString "/" (lib.removePrefix "//" v.device))) (lib.attrValues smb));
  smbLocal = map (n: lib.removePrefix "/mnt/nicol_nas/smb/${user}/" n) smbNames;

  withSshfs = (sys.extendModules {
    modules = [{ myconfig.krit.services.nas.sshfs.enable = lib.mkForce true; }];
  }).config;
  sshfsMp = "/mnt/nicol_nas/ssh/system_root";
  sshfsFs = withSshfs.fileSystems.${sshfsMp};

  dav = fsOf "davfs";
  davPrefix = "/mnt/nicol_nas/webdav/opencloud/";
  spaces = my.krit.services.nas.opencloud-mount.spaces;

  uuidByHost = { nixos-desktop = "7E70DDB470DD737F"; nixos-laptop = "26C47F73C47F43D9"; };
  win = fs."/mnt/windows";
  badHost = (sys.extendModules {
    modules = [{ myconfig.constants.hostname = lib.mkForce "no-such-host"; }];
  }).config;
  winFailing = c: builtins.filter (a: lib.hasInfix "windows-mount" a.message) (builtins.filter (a: !a.assertion) c.assertions);

  mounts = my.services.rcloneMount.mounts;
  cloudModules = my.krit.services.cloud;
  cloudEnabled = builtins.filter (n: cloudModules.${n}.enable) (builtins.attrNames cloudModules);
  rcloneSecretFor = m: lib.findFirst (n: cfg.sops.secrets.${n}.path == m.configFile) null
    (builtins.filter (lib.hasPrefix "rclone_") (builtins.attrNames cfg.sops.secrets));
  hm = c: c.home-manager.users.${user}.systemd.user.services;
  rcloneUnit = m: (hm cfg)."rclone-mount-${m.name}";
  one = v: if builtins.isList v then builtins.concatStringsSep " " v else v;
  execOf = m: one (rcloneUnit m).Service.ExecStart;

  asList = v: if builtins.isList v then v else if v == null then [ ] else [ v ];
  envOf = svc: asList (svc.Service.Environment or null);
  hmUnitSets =
    [{ label = "base"; units = hm cfg; }]
    ++ lib.mapAttrsToList (n: s: { label = "spec:${n}"; units = hm s.configuration; }) cfg.specialisation;
  hmLiteralPath = lib.concatMap
    (set: lib.concatMap
      (u: map (_: "${set.label}/${u}") (builtins.filter (lib.hasInfix "$PATH") (envOf set.units.${u})))
      (builtins.attrNames set.units))
    hmUnitSets;
  sysLiteralPath = builtins.filter
    (n: builtins.any (lib.hasInfix "$PATH") (asList (cfg.systemd.services.${n}.serviceConfig.Environment or null)))
    (builtins.attrNames cfg.systemd.services);

  userCfg = cfg.users.users.${user};
  gidOf = c: toString c.users.groups.${c.users.users.${user}.group}.gid;
  uidOf = c: toString c.users.users.${user}.uid;

  checks = {
    check-user-uid-pinned = check (userCfg.uid == 1000) "users.users.${user}.uid is ${toString userCfg.uid}, expected 1000";
    check-sshfs-uid-gid = check
      (optVal "uid=" sshfsFs.options == uidOf withSshfs && optVal "gid=" sshfsFs.options == gidOf withSshfs && uidOf withSshfs != "")
      "sshfs uid=/gid= differ from the user's configured uid / primary group gid";
    check-windows-uid-gid = check
      (optVal "uid=" win.options == uidOf cfg && optVal "gid=" win.options == gidOf cfg && uidOf cfg != "")
      "ntfs3 uid=/gid= differ from the user's configured uid / primary group gid";
    check-davfs-uid-gid = check
      (lib.all (v: optVal "uid=" v.options == user) (lib.attrValues dav))
      "a davfs mount uid= is not the constants.user name";
    check-smb-mounts-under-user-dir = check (smbNames != [ ] && lib.all (n: lib.hasPrefix "/mnt/nicol_nas/smb/${user}/" n) smbNames)
      "cifs mounts: ${builtins.toJSON smbNames}";
    check-smb-single-nas-host = check (builtins.length smbDevHosts == 1 && lib.all (v: lib.hasPrefix "//" v.device) (lib.attrValues smb))
      "cifs device hosts: ${builtins.toJSON smbDevHosts}";
    check-smb-share-names-nonempty = check (lib.all (v: builtins.length (lib.splitString "/" (lib.removePrefix "//" v.device)) == 2 && builtins.elemAt (lib.splitString "/" (lib.removePrefix "//" v.device)) 1 != "") (lib.attrValues smb))
      "empty share name in a cifs device";
    check-smb-local-names-unique = check (unique smbLocal && lib.all (n: n != "" && !(lib.hasInfix " " n)) smbLocal)
      "localNames: ${builtins.toJSON smbLocal}";
    check-smb-credentials = check
      (lib.all (v: optVal "credentials=" v.options == cfg.sops.secrets.nas-krit-credentials.path && cfg.sops.secrets.nas-krit-credentials.path != "") (lib.attrValues smb))
      "credentials= empty or not the nas-krit-credentials sops path";
    check-smb-vers = check (lib.all (v: has "vers=3.1.1" v.options) (lib.attrValues smb)) "a cifs mount lacks vers=3.1.1";
    check-smb-automount = check (lib.all (v: has "noauto" v.options && has "x-systemd.automount" v.options && has "_netdev" v.options && has "nofail" v.options) (lib.attrValues smb))
      "a cifs mount lacks noauto/x-systemd.automount/_netdev/nofail";
    check-smb-uid-gid = check
      (lib.all (v: optVal "uid=" v.options == user && optVal "gid=" v.options == cfg.users.users.${user}.group) (lib.attrValues smb))
      "cifs uid= is not the constants.user name or gid= not the user's primary group name";
    check-smb-fsc-needs-cachefilesd = check
      (!(lib.any (v: has "fsc" v.options) (lib.attrValues smb)) || cfg.services.cachefilesd.enable)
      "fsc mounts present but services.cachefilesd disabled";
    check-smb-fsc-used = check (lib.any (v: has "fsc" v.options) (lib.attrValues smb))
      "no cifs mount uses fsc, so the cachefilesd check is vacuous";
    check-nas-root-tmpfiles = check (has "d /mnt/nicol_nas 0700 ${user} users -" cfg.systemd.tmpfiles.rules)
      "tmpfiles lacks d /mnt/nicol_nas 0700 ${user} users -";
    check-nas-root-no-looser-rule = check
      (builtins.all (r: !(lib.hasPrefix "d /mnt/nicol_nas " r) || lib.hasInfix " 0700 " r) cfg.systemd.tmpfiles.rules)
      "a tmpfiles rule creates /mnt/nicol_nas with a mode other than 0700";

    check-sshfs-disabled-no-mount = check (!(fs ? ${sshfsMp}) || my.krit.services.nas.sshfs.enable)
      "sshfs mount present although sshfs.enable=false";
    check-sshfs-when-enabled = check
      (sshfsFs.fsType == "fuse.sshfs" && has "noauto" sshfsFs.options && has "x-systemd.automount" sshfsFs.options)
      "sshfs fs wrong type or not automount";
    check-sshfs-identity = check
      (optVal "IdentityFile=" sshfsFs.options == withSshfs.sops.secrets.nas_ssh_key.path && optVal "IdentityFile=" sshfsFs.options != "")
      "IdentityFile= empty or not the nas_ssh_key sops path";
    check-sshfs-same-host-as-smb = check
      (builtins.head (lib.splitString ":" (lib.last (lib.splitString "@" sshfsFs.device))) == builtins.head smbDevHosts)
      "sshfs host ${sshfsFs.device} differs from smb host ${builtins.toJSON smbDevHosts}";

    check-davfs-count-matches-spaces = check
      (builtins.length spaces > 0 && builtins.length (builtins.attrNames dav) == builtins.length spaces)
      "davfs mounts ${toString (builtins.length (builtins.attrNames dav))} vs spaces ${toString (builtins.length spaces)}";
    check-davfs-paths = check (lib.all (n: lib.hasPrefix davPrefix n) (builtins.attrNames dav)) "davfs mount outside ${davPrefix}";
    check-davfs-automount = check (lib.all (v: has "noauto" v.options && has "x-systemd.automount" v.options) (lib.attrValues dav))
      "davfs mount lacks noauto/x-systemd.automount";
    check-davfs-device-urls = check (lib.all (v: lib.hasPrefix "https://" v.device) (lib.attrValues dav)) "davfs device is not an https URL";
    check-davfs-secrets-wired = check
      (my.krit.services.nas.opencloud-mount.secretsFile != "" && cfg.environment.etc."davfs2/secrets".source == my.krit.services.nas.opencloud-mount.secretsFile)
      "davfs2 secrets file empty or not wired to /etc/davfs2/secrets";
    check-davfs-university-0700 = check (has "d ${lib.removeSuffix "/" davPrefix}/University 0700 ${user} users -" cfg.systemd.tmpfiles.rules)
      "University dir not 0700";

    check-windows-uuid = check (win.device == "/dev/disk/by-uuid/${uuidByHost.${host}}" && win.fsType == "ntfs3")
      "windows device=${win.device} fsType=${win.fsType}";
    check-windows-assertion-passes = check (winFailing cfg == [ ])
      "windows-mount assertion failing on the real host";
    check-windows-assertion-fires-on-unknown-host = check (builtins.length (winFailing badHost) == 1)
      "windows-mount assertion did not fire for an unmapped hostname";

    check-rclone-enabled-matches-cloud-modules = check
      (builtins.length mounts == builtins.length cloudEnabled && mounts != [ ])
      "${toString (builtins.length mounts)} rclone mounts vs ${toString (builtins.length cloudEnabled)} enabled cloud modules";
    check-rclone-names-unique = check (unique (map (m: m.name) mounts) && lib.all (m: m.name != "") mounts)
      "rclone mount names: ${builtins.toJSON (map (m: m.name) mounts)}";
    check-rclone-fields-nonempty = check
      (lib.all (m: m.remote != "" && m.configFile != "" && m.mountPoint != "" && lib.hasSuffix ":" m.remote) mounts)
      "an rclone mount has an empty remote/configFile/mountPoint";
    check-rclone-mountpoints-unique = check
      (unique (map (m: m.mountPoint) mounts) && lib.all (m: !(fs ? ${m.mountPoint})) mounts)
      "rclone mountPoints collide with each other or a fileSystems entry";
    check-rclone-units-exist = check (lib.all (m: hm cfg ? "rclone-mount-${m.name}") mounts) "an rclone mount has no HM user unit";
    check-rclone-execstart = check
      (lib.all (m: let e = execOf m; in lib.hasInfix "--config ${m.configFile}" e && lib.hasInfix " ${m.remote} ${m.mountPoint} " e) mounts)
      "ExecStart lacks configFile/remote/mountPoint";
    check-rclone-execstop = check
      (lib.all (m: lib.hasSuffix " -u ${m.mountPoint}" (one (rcloneUnit m).Service.ExecStop)) mounts)
      "ExecStop does not unmount the mountPoint";
    check-rclone-tmpfiles = check
      (lib.all (m: has "d ${m.mountPoint} 0755 ${user} users -" cfg.systemd.tmpfiles.rules) mounts)
      "a mountPoint has no tmpfiles rule";
    check-rclone-sops-secret-declared = check
      (lib.all (m: rcloneSecretFor m != null && cfg.sops.secrets.${rcloneSecretFor m}.owner == user) mounts)
      "an rclone configFile is not a declared rclone_* sops secret owned by the user";
    check-rclone-sops-file-has-key = check
      (lib.all (m: let n = rcloneSecretFor m; s = cfg.sops.secrets.${n}; in builtins.pathExists s.sopsFile && lib.hasInfix "\n${n}:" ("\n" + builtins.readFile s.sopsFile)) mounts)
      "sopsFile missing or lacks the rclone secret key";
    check-no-literal-PATH-in-hm-units = check (hmLiteralPath == [ ])
      "systemd does not expand $PATH in Environment=; offending HM units (base and specialisations): ${builtins.toJSON hmLiteralPath}";
    check-no-literal-PATH-in-system-units = check (sysLiteralPath == [ ])
      "offending system units: ${builtins.toJSON sysLiteralPath}";
    check-sweep-covers-school-unit = check
      (lib.any (set: set.label == "spec:school" && set.units ? school-onedrive-mount) hmUnitSets)
      "unit sweep does not see school-onedrive-mount, so the PATH sweep is incomplete";
  };
  guard = v: let r = builtins.tryEval (builtins.deepSeq v v); in if r.success then r.value else "FAIL: eval error (option missing or throw)";
in
lib.mapAttrs (_: guard) checks
