let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  host = flake.darwinConfigurations.Krits-MacBook-Pro;
  config = host.config;
  my = config.myconfig;
  nas = my.krit.services.nas;
  user = my.constants.user;
  home = config.users.users.${user}.home;
  hostName = config.networking.hostName;

  borgText = config.environment.etc."borgmatic/config.yaml".text;
  borg = builtins.fromJSON borgText;
  agent = config.launchd.user.agents.borgmatic-backup.serviceConfig;
  postAct = cfg: cfg.system.activationScripts.postActivation.text;

  check = name: cond: detail:
    if cond then "ok" else "FAIL: ${name}: ${detail}";

  checkEq = name: actual: expected:
    check name (actual == expected) "expected ${builtins.toJSON expected}, got ${builtins.toJSON actual}";

  hasLine = text: line: builtins.elem line (lib.splitString "\n" text);

  badHostKeyPolicy = s: lib.hasInfix "StrictHostKeyChecking" s || lib.hasInfix "accept-new" s || lib.hasInfix "UserKnownHostsFile" s;

  smbMkdir = "mkdir -p ${nas.mountRoot}/smb";
  smbChown = "chown ${user} ${nas.mountRoot} ${nas.mountRoot}/smb";

  withoutSmb = host.extendModules {
    modules = [ ({ lib, ... }: { myconfig.krit.services.nas.smb.enable = lib.mkForce false; }) ];
  };
  withAllShares = host.extendModules {
    modules = [
      ({ lib, ... }: {
        myconfig.krit.services.nas.opencloud.enable = lib.mkForce true;
        myconfig.krit.services.nas.sshfs.enable = lib.mkForce true;
      })
    ];
  };
  opencloudRoot = "${nas.mountRoot}/webdav/opencloud";
  sshfsMount = "${nas.mountRoot}/ssh/system_root";
in
{
  check-mount-root = checkEq "krit.services.nas.mountRoot on darwin" nas.mountRoot "/Volumes/nicol_nas";
  check-nas-user = checkEq "krit.services.nas.user (NAS-side account)" nas.user "krit";
  check-nas-host-fqdn =
    check "krit.services.nas.host is a dotted FQDN, not a short alias"
      (lib.hasInfix "." nas.host && nas.host != nas.tailnetIp)
      "host=${nas.host}";

  check-known-hosts-pin =
    let pin = config.programs.ssh.knownHosts."nicol-nas-tailnet"; in
    check "programs.ssh.knownHosts.nicol-nas-tailnet pins host + tailnetIp with nas.hostKey"
      (pin.hostNames == [ nas.host nas.tailnetIp ] && pin.publicKey == nas.hostKey)
      "hostNames=${builtins.toJSON pin.hostNames}";
  check-host-key-shape =
    check "nas.hostKey is a non-empty ssh-ed25519 public key line"
      (lib.hasPrefix "ssh-ed25519 " nas.hostKey && builtins.stringLength nas.hostKey > 20)
      "hostKey has the wrong shape";

  check-repo-url =
    let r = builtins.head borg.repositories; in
    checkEq "borgmatic repository path = ssh://<nas.user>@<nas.host>/<dir>/<hostName>" r.path
      "ssh://${nas.user}@${nas.host}/volume1/Default-volume-1/0001_Docker/borgitory/${hostName}";
  check-repo-single =
    checkEq "borgmatic has exactly one repository" (builtins.length borg.repositories) 1;
  check-source-home = checkEq "borgmatic source_directories" borg.source_directories [ home ];

  check-excludes-secrets =
    let must = [ "${home}/.ssh" "${home}/.config/sops" "${home}/dotfiles-private" ];
        missing = builtins.filter (e: !(builtins.elem e borg.exclude_patterns)) must;
    in
    check "exclude_patterns hold .ssh, .config/sops, dotfiles-private" (missing == [ ])
      "missing ${builtins.toJSON missing}";
  check-excludes-control =
    let must = [ "${home}/.ssh" "${home}/.config/sops" "${home}/dotfiles-private" ];
        trimmed = builtins.filter (e: e != "${home}/.ssh") borg.exclude_patterns;
        missing = builtins.filter (e: !(builtins.elem e trimmed)) must;
    in
    check "control: dropping .ssh from the list is detected" (missing == [ "${home}/.ssh" ])
      "missing ${builtins.toJSON missing}";

  check-ssh-command-strict =
    check "borgmatic ssh_command has no StrictHostKeyChecking / accept-new / UserKnownHostsFile override"
      (!(badHostKeyPolicy borg.ssh_command))
      "ssh_command=${borg.ssh_command}";
  check-no-accept-new-anywhere =
    check "no accept-new / StrictHostKeyChecking in the whole borgmatic config or agent"
      (!(badHostKeyPolicy borgText) && !(badHostKeyPolicy (builtins.toJSON agent)))
      "found in borgmatic config or launchd agent";
  check-ssh-policy-control =
    check "control: the host-key-policy predicate flags an accept-new ssh_command"
      (badHostKeyPolicy "ssh -o StrictHostKeyChecking=accept-new" && badHostKeyPolicy "ssh -o StrictHostKeyChecking=no")
      "predicate is blind";
  check-ssh-identity =
    check "ssh_command uses the sops borg-private-key path with IdentitiesOnly"
      (lib.hasInfix "-i ${config.sops.secrets.borg-private-key.path} " borg.ssh_command && lib.hasInfix "IdentitiesOnly=yes" borg.ssh_command)
      "ssh_command=${borg.ssh_command}";
  check-passcommand =
    checkEq "encryption_passcommand reads the sops borg-passphrase path" borg.encryption_passcommand
      "cat ${config.sops.secrets.borg-passphrase.path}";

  check-schedule =
    let hours = map (s: s.Hour) agent.StartCalendarInterval; mins = map (s: s.Minute) agent.StartCalendarInterval; in
    check "StartCalendarInterval is 10:00, 14:00, 22:00" (hours == [ 10 14 22 ] && mins == [ 0 0 0 ])
      "hours=${builtins.toJSON hours} minutes=${builtins.toJSON mins}";
  check-no-run-at-load =
    check "borgmatic agent has no RunAtLoad (a rebuild must not trigger a full backup)"
      (!(agent ? RunAtLoad) || agent.RunAtLoad != true) "RunAtLoad is set";
  check-agent-config-path =
    check "agent ProgramArguments --config points at the generated /etc file"
      (builtins.elem "/etc/borgmatic/config.yaml" agent.ProgramArguments && config.environment.etc ? "borgmatic/config.yaml")
      "args=${builtins.toJSON agent.ProgramArguments}";

  check-smb-mkdir-in-activation =
    check "postActivation (the only spliced slot) holds the smb mkdir and chown lines"
      (hasLine (postAct config) smbMkdir && hasLine (postAct config) smbChown)
      "missing '${smbMkdir}' / '${smbChown}' in postActivation";
  check-smb-mkdir-control =
    check "control: with smb disabled the smb mkdir line disappears"
      (!(hasLine (postAct withoutSmb.config) smbMkdir))
      "line still present with smb disabled";
  check-other-shares-mkdir =
    let t = postAct withAllShares.config; in
    check "control: enabling opencloud + sshfs puts their mkdir lines into postActivation"
      (hasLine t "mkdir -p ${opencloudRoot}/Personal" && hasLine t "mkdir -p ${sshfsMount}")
      "opencloud/sshfs mkdir lines missing";

  check-tailscale-assertion =
    let msgs = map (a: a.message) (builtins.filter (a: !a.assertion) config.assertions); in
    check "no failing assertions (tailnet provider present for the NAS modules)" (msgs == [ ]) (builtins.toJSON msgs);
}
