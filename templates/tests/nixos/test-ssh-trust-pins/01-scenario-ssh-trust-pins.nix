let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  isDarwinHost = !(flake.nixosConfigurations ? ${host});
  sys = flake.nixosConfigurations.${host} or flake.darwinConfigurations.${host};
  cfg = sys.config;
  user = cfg.myconfig.constants.user;
  hmNixos = cfg.home-manager.users.${user};
  hmHome = flake.homeConfigurations."${user}@${host}".config;

  lines = text: lib.filter (l: lib.trim l != "") (lib.splitString "\n" text);
  fields = l: lib.filter (f: f != "") (lib.splitString " " (lib.trim l));

  hmKnownText = hmHome.home.file.".ssh/known_hosts".text;
  hmKnownLines = lines hmKnownText;
  nixosKnown = lib.mapAttrs (_: v: v.publicKey) cfg.programs.ssh.knownHosts;
  nixosOnlyPins = [ "nicol-nas-tailnet" ];
  nixosMirrored = removeAttrs nixosKnown nixosOnlyPins;

  keyOf = l: let f = fields l; in "${lib.elemAt f 1} ${lib.elemAt f 2}";
  hmKeysFor = h: map keyOf (lib.filter (l: lib.head (fields l) == h) hmKnownLines);

  parseExtra = text:
    let
      step = acc: raw:
        let
          l = lib.trim raw;
          f = fields l;
        in
        if l == "" || lib.hasPrefix "#" l then acc
        else if lib.head f == "Host" then acc // { cur = lib.concatStringsSep " " (lib.tail f); hosts = acc.hosts // { ${lib.concatStringsSep " " (lib.tail f)} = { }; }; }
        else acc // { hosts = acc.hosts // { ${acc.cur} = acc.hosts.${acc.cur} // { ${lib.head f} = lib.concatStringsSep " " (lib.tail f); }; }; };
    in
    (lib.foldl' step { cur = ""; hosts = { }; } (lib.splitString "\n" text)).hosts;

  extra = parseExtra cfg.programs.ssh.extraConfig;
  hmSettings = hmNixos.programs.ssh.settings;
  hmHomeSettings = hmHome.programs.ssh.settings;
  aliasesOf = lib.attrNames;
  plain = v: removeAttrs (v.data or v) [ "header" ];

  show = builtins.toJSON;
  expect = name: ok: detail: if ok then "ok" else "FAIL: ${name}: ${detail}";

  commonChecks = {
    "NixOS knownHosts pins at least one host with a literal key" =
      expect "knownHosts" (nixosKnown != { } && lib.all (k: k != null && builtins.length (fields k) == 2) (lib.attrValues nixosKnown))
        "got ${show nixosKnown}";
    "known_hosts text is non-empty and every line has exactly 3 fields" =
      expect "fields" (hmKnownLines != [ ] && lib.all (l: builtins.length (fields l) == 3) hmKnownLines)
        "bad lines: ${show (lib.filter (l: builtins.length (fields l) != 3) hmKnownLines)}";
    "known_hosts has no duplicate (host, key type) pair" =
      let pairs = map (l: "${lib.elemAt (fields l) 0} ${lib.elemAt (fields l) 1}") hmKnownLines; in
      expect "dups" (lib.unique pairs == pairs) "duplicates in ${show pairs}";
    "every NixOS-pinned key appears verbatim in HM known_hosts for that host" =
      let missing = lib.filter (h: !(builtins.elem nixosMirrored.${h} (hmKeysFor h))) (lib.attrNames nixosMirrored); in
      expect "copies" (missing == [ ]) "NixOS key not in HM known_hosts (or differs) for: ${show missing}";
    "every non-github.com host pinned in HM known_hosts has a NixOS knownHosts entry" =
      let
        hmHosts = lib.unique (map (l: lib.head (fields l)) hmKnownLines);
        unpinned = lib.filter (h: !(nixosMirrored ? ${h}) && !(lib.hasSuffix "github.com" h)) hmHosts;
      in
      expect "reverse" (unpinned == [ ]) "HM pins hosts with no NixOS pin: ${show unpinned}";
  };

  nas = cfg.myconfig.krit.services.nas;
  nasPin = cfg.programs.ssh.knownHosts."nicol-nas-tailnet" or { hostNames = [ ]; publicKey = ""; };
  gatewayOpt = sys.options.myconfig.krit.system.ssh-config.gatewayAlias;
  noGateway = (sys.extendModules { modules = [{ myconfig.krit.system.ssh-config.gatewayAlias = lib.mkForce false; }]; }).config;
  withSshfs = (sys.extendModules { modules = [{ myconfig.krit.services.nas.sshfs.enable = lib.mkForce true; }]; }).config;
  sshfsOptions = withSshfs.fileSystems."${nas.mountRoot}/ssh/system_root".options;
  borgSshCommands = lib.mapAttrsToList (_: c: c.ssh_command or "") cfg.services.borgmatic.configurations;

  nixosOnlyChecks = {
    "NAS ed25519 key is pinned for both the FQDN and the tailnet IP (NixOS-only pin, exempt from the HM mirror)" =
      expect "nas-pin"
        (lib.hasPrefix "ssh-ed25519 " nasPin.publicKey && nasPin.publicKey == nas.hostKey
          && builtins.elem nas.host nasPin.hostNames && builtins.elem nas.tailnetIp nasPin.hostNames
          && (extra."nicol-nas".HostName or "") == nas.host)
        "got ${show nasPin} (nas.host=${nas.host} tailnetIp=${nas.tailnetIp}, Host nicol-nas HostName=${show (extra."nicol-nas".HostName or null)})";
    "borgmatic ssh_command and the sshfs mount carry no StrictHostKeyChecking override" =
      let bad = lib.filter (c: lib.hasInfix "StrictHostKeyChecking" c) (borgSshCommands ++ sshfsOptions); in
      expect "no-strict-off" (borgSshCommands != [ ] && sshfsOptions != [ ] && bad == [ ]) "got ${show bad}";
    "ssh-config.gatewayAlias exists, defaults to false and is the only switch for the gateway alias" =
      let noExtra = parseExtra noGateway.programs.ssh.extraConfig; in
      expect "gateway-opt"
        (gatewayOpt.default == false && cfg.myconfig.krit.system.ssh-config.gatewayAlias
          && !(noExtra ? gateway) && !(noGateway.home-manager.users.${user}.programs.ssh.settings ? gateway))
        "default=${show gatewayOpt.default} real=${show cfg.myconfig.krit.system.ssh-config.gatewayAlias} extraWithout=${show (noExtra ? gateway)}";
    "Host alias set: NixOS extraConfig == HM programs.ssh.settings" =
      expect "aliases" (aliasesOf extra == aliasesOf hmSettings)
        "extraConfig=${show (aliasesOf extra)} hm=${show (aliasesOf hmSettings)}";
    "Host option values: NixOS extraConfig == HM settings, per alias" =
      let
        norm = s: lib.mapAttrs (_: toString) (plain s);
        bad = lib.filter (a: norm (extra.${a} or { }) != norm (hmSettings.${a} or { })) (aliasesOf hmSettings);
      in
      expect "values" (bad == [ ]) "differ for ${show bad}: extra=${show (lib.genAttrs bad (a: extra.${a} or null))} hm=${show (lib.genAttrs bad (a: plain hmSettings.${a}))}";
    "gateway alias present in both NixOS extraConfig and HM settings" =
      expect "gateway" (extra ? gateway && hmSettings ? gateway) "extra=${show (extra ? gateway)} hm=${show (hmSettings ? gateway)}";
    "standalone home settings aliases (minus *) are a subset of NixOS aliases" =
      let
        homeAliases = lib.filter (a: a != "*") (aliasesOf hmHomeSettings);
        extraAliases = lib.filter (a: !(builtins.elem a (aliasesOf extra))) homeAliases;
      in
      expect "subset" (extraAliases == [ ]) "only in standalone home: ${show extraAliases}";
    "standalone home UserKnownHostsFile covers known_hosts and known_hosts.local" =
      let v = (plain (hmHomeSettings."*" or { })).UserKnownHostsFile or ""; in
      expect "ukhf" (lib.hasInfix "~/.ssh/known_hosts " (v + " ") && lib.hasInfix "known_hosts.local" v) "got ${show v}";
    "tmpfiles creates ~/.ssh with mode 0700 owned by the user" =
      let want = "d /home/${user}/.ssh 0700 ${user} users -"; in
      expect "tmpfiles" (builtins.elem want cfg.systemd.tmpfiles.rules) "rule ${show want} not in rules";
    "gnupg agent on but SSH support off (gcr is the sole SSH agent)" =
      expect "gnupg" (cfg.programs.gnupg.agent.enable && !cfg.programs.gnupg.agent.enableSSHSupport)
        "enable=${show cfg.programs.gnupg.agent.enable} sshSupport=${show cfg.programs.gnupg.agent.enableSSHSupport}";
    "git: gpg.format == ssh, commit.gpgSign == true, allowedSignersFile set" =
      let g = hmNixos.programs.git.settings; in
      expect "git" (g.gpg.format == "ssh" && g.commit.gpgSign == true && lib.hasSuffix "/.ssh/allowed_signers" g.gpg.ssh.allowedSignersFile)
        "got ${show { fmt = g.gpg.format; sign = g.commit.gpgSign; file = g.gpg.ssh.allowedSignersFile; }}";
    "allowed_signers has one line of the form '<email> <type> <key>'" =
      let l = lines hmNixos.home.file.".ssh/allowed_signers".text; in
      expect "signers" (builtins.length l == 1 && builtins.length (fields (lib.head l)) == 3)
        "got ${show l}";
  };

  twin = mods: (sys.extendModules { modules = mods; }).config;
  borgModule = "Krits-MacBook-Pro-borg-backup";
  dOn = twin [{
    myconfig.krit = {
      services.nas.sshfs.enable = lib.mkForce true;
      services.nas.${borgModule}.enable = lib.mkForce true;
      system.git-ssh-signing.enable = lib.mkForce true;
    };
  }];
  dHm = c: c.home-manager.users.${user};
  borgText = c: c.environment.etc."borgmatic/config.yaml".text;
  sshfsScript = c: c.launchd.user.agents.sshfs-nas.script;
  pinOf = c: c.programs.ssh.knownHosts."nicol-nas-tailnet" or { hostNames = [ ]; publicKey = ""; };
  noComments = text: lib.concatStringsSep "\n" (lib.filter (l: !(lib.hasPrefix "#" (lib.trim l))) (lib.splitString "\n" text));

  pinOk = c:
    let p = pinOf c; in
    lib.hasPrefix "ssh-ed25519 " p.publicKey && p.publicKey == nas.hostKey
    && builtins.elem nas.host p.hostNames && builtins.elem nas.tailnetIp p.hostNames;
  borgTrustOk = c: pin:
    let
      b = builtins.fromJSON (borgText c);
      cmd = b.ssh_command or "";
      hostOf = path: lib.last (lib.splitString "@" (lib.head (lib.splitString "/" (lib.removePrefix "ssh://" path))));
    in
    b.repositories != [ ]
    && lib.all (r: lib.hasPrefix "ssh://${nas.user}@${nas.host}/" r.path && builtins.elem (hostOf r.path) pin.hostNames) b.repositories
    && lib.hasInfix "IdentitiesOnly=yes" cmd
    && !(lib.hasInfix "StrictHostKeyChecking" cmd) && !(lib.hasInfix "accept-new" cmd);
  sshfsTrustOk = c: pin:
    let code = noComments (sshfsScript c); in
    lib.hasInfix "sshfs " code
    && lib.any (h: lib.hasInfix "@${h}:" code) pin.hostNames
    && !(lib.hasInfix "StrictHostKeyChecking" code) && !(lib.hasInfix "accept-new" code);

  gitFailures = c:
    let
      home = c.users.users.${user}.home;
      hm = dHm c;
      ini = hm.programs.git.iniContent;
      gs = hm.programs.git.settings;
      school = lib.filter (i: i.condition == "gitdir:~/school-workspace/**") hm.programs.git.includes;
      su = if school == [ ] then { } else (lib.head school).contents.user;
      schoolEmail = su.email or "";
      schoolKey = su.signingKey or su.signingkey or "";
      baseKey = ini.user.signingKey or "";
      signerLines = lines ((hm.home.file.".ssh/allowed_signers" or { }).text or "");
      signerFields = map fields signerLines;
      principals = map lib.head signerFields;
      sshDir = "${home}/.ssh/";
    in
    lib.optional ((ini.gpg.format or "") != "ssh") "gpg.format is not ssh"
    ++ lib.optional ((ini.commit.gpgSign or false) != true) "commit.gpgSign is not true"
    ++ lib.optional ((ini.tag.gpgSign or false) != true) "tag.gpgSign is not true"
    ++ lib.optional (!(lib.hasPrefix sshDir baseKey)) "user.signingKey '${baseKey}' is not under ${sshDir}"
    ++ lib.optional ((ini.gpg.ssh.allowedSignersFile or "") != "${sshDir}allowed_signers") "allowedSignersFile is '${ini.gpg.ssh.allowedSignersFile or "unset"}'"
    ++ lib.optional (builtins.length school != 1) "expected exactly one gitdir:~/school-workspace/** include, got ${toString (builtins.length school)}"
    ++ lib.optional (schoolEmail == "" || schoolEmail == (ini.user.email or "")) "school include email '${schoolEmail}' empty or equal to the base email"
    ++ lib.optional (!(lib.hasPrefix sshDir schoolKey) || schoolKey == baseKey) "school include signing key '${schoolKey}' not under ${sshDir} or equal to the base key"
    ++ lib.optional (signerLines == [ ] || lib.any (f: builtins.length f != 3 || lib.elemAt f 1 != "ssh-ed25519") signerFields) "allowed_signers lines are not '<principal> ssh-ed25519 <key>': ${show signerLines}"
    ++ lib.optional (principals == [ ] || lib.head principals != (ini.user.email or "")) "first allowed_signers principal is not the git user.email"
    ++ lib.optional (!(builtins.elem schoolEmail principals)) "school principal missing from allowed_signers"
    ++ lib.optional (hm.programs.git.signing.key != null || gs.user ? signingkey) "signing.key or lowercase user.signingkey is set (single source: git-ssh-signing)";

  dBroken = twin [{
    programs.ssh.knownHosts = lib.mkForce { };
    environment.etc."borgmatic/config.yaml".text = lib.mkForce (builtins.replaceStrings [ "IdentitiesOnly=yes" ] [ "StrictHostKeyChecking=accept-new" ] (borgText dOn));
    launchd.user.agents.sshfs-nas.script = lib.mkForce (sshfsScript dOn + "\n  -o StrictHostKeyChecking=accept-new\n");
    myconfig.krit.system.git-ssh-signing.extraAllowedSigners = lib.mkForce [ ];
    home-manager.users.${user}.programs.git.signing.signByDefault = lib.mkForce false;
  }];

  dOvr = twin [{
    home-manager.users.${user}.programs.git = {
      signing.signByDefault = lib.mkOverride 90 false;
      settings = {
        commit.gpgSign = lib.mkOverride 90 false;
        gpg.format = lib.mkOverride 90 "openpgp";
        gpg.ssh.allowedSignersFile = lib.mkOverride 90 "/override";
        user.signingKey = lib.mkOverride 90 "/override";
        probe.forced = lib.mkMerge [ (lib.mkForce "forced") (lib.mkOverride 90 "over") ];
        probe.plain = lib.mkMerge [ "plain" (lib.mkOverride 90 "over") ];
      };
    };
  }];
  ovrIni = (dHm dOvr).programs.git.iniContent;
  pinOn = pinOf dOn;

  darwinChecks = {
    "knownHosts pins at least one host with a literal key" = commonChecks."NixOS knownHosts pins at least one host with a literal key";
  };

  darwinNasChecks = {
    "darwin NAS ed25519 key is pinned for both the FQDN and the tailnet IP" =
      expect "darwin-nas-pin"
        (pinOk cfg && ((plain hmSettings."nicol-nas").HostName or "") == nas.host)
        "got ${show (pinOf cfg)} (nas.host=${nas.host} tailnetIp=${nas.tailnetIp}, Host nicol-nas HostName=${show ((plain hmSettings."nicol-nas").HostName or null)})";
    "darwin borg: FQDN repo of the pinned host, IdentitiesOnly=yes, no host-key override" =
      expect "darwin-borg" (borgTrustOk dOn pinOn)
        "repositories=${show (builtins.fromJSON (borgText dOn)).repositories} ssh_command=${show (builtins.fromJSON (borgText dOn)).ssh_command or null}";
    "darwin sshfs script connects to a pinned host and carries no host-key override" =
      expect "darwin-sshfs" (sshfsTrustOk dOn pinOn) "script code: ${noComments (sshfsScript dOn)}";
    "control: darwin pin check fails with the knownHosts emptied" =
      expect "ctl-pin" (!(pinOk dBroken)) "pinOk accepted a host without the NAS pin";
    "control: darwin borg check fails with accept-new and no IdentitiesOnly" =
      expect "ctl-borg" (!(borgTrustOk dBroken pinOn)) "borgTrustOk accepted StrictHostKeyChecking=accept-new";
    "control: darwin sshfs check fails with accept-new appended" =
      expect "ctl-sshfs" (!(sshfsTrustOk dBroken pinOn)) "sshfsTrustOk accepted StrictHostKeyChecking=accept-new";
  };

  darwinGitChecks = {
    "darwin git signing: ssh format under ~/.ssh, school include, allowed_signers incl. school principal, tag+commit signed (iniContent)" =
      let f = gitFailures dOn; in expect "darwin-git" (f == [ ]) "failures: ${show f}";
    "darwin git signing stays overridable at priority 90 (no mkForce on signByDefault, gpgSign, format, key, allowedSignersFile)" =
      expect "darwin-git-force"
        (!(dHm dOvr).programs.git.signing.signByDefault && ovrIni.commit.gpgSign == false && ovrIni.gpg.format == "openpgp"
          && ovrIni.user.signingKey == "/override" && ovrIni.gpg.ssh.allowedSignersFile == "/override")
        "signByDefault=${show (dHm dOvr).programs.git.signing.signByDefault} ini=${show { c = ovrIni.commit.gpgSign or null; f = ovrIni.gpg.format or null; k = ovrIni.user.signingKey or null; a = ovrIni.gpg.ssh.allowedSignersFile or null; }}";
    "control: a mkForce'd leaf resists the priority-90 override, a plain one does not" =
      expect "ctl-force" (ovrIni.probe.forced == "forced" && ovrIni.probe.plain == "over")
        "forced=${show ovrIni.probe.forced or null} plain=${show ovrIni.probe.plain or null}";
    "control: git check flags signByDefault forced off (missing tag.gpgSign)" =
      expect "ctl-tag" (builtins.elem "tag.gpgSign is not true" (gitFailures dBroken)) "got ${show (gitFailures dBroken)}";
    "control: git check flags a missing school principal in allowed_signers" =
      expect "ctl-school-signer" (builtins.elem "school principal missing from allowed_signers" (gitFailures dBroken)) "got ${show (gitFailures dBroken)}";
  };

  nixosGiteaKey = flake.nixosConfigurations.nixos-desktop.config.programs.ssh.knownHosts."gitea-ssh.nicolkrit.ch".publicKey;
  darwinCheck = {
    "Darwin gitea pin equals the NixOS gitea pin" =
      expect "darwin-vs-nixos" (nixosKnown."gitea-ssh.nicolkrit.ch" == nixosGiteaKey)
        "darwin=${show (nixosKnown."gitea-ssh.nicolkrit.ch" or null)} nixos=${show nixosGiteaKey}";
  };

  final = if isDarwinHost then darwinChecks // darwinCheck // darwinNasChecks // darwinGitChecks else commonChecks // nixosOnlyChecks;
in
{
  report = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}\t${v}") final) + "\n";
  nixosPins = lib.concatStringsSep "\n" (lib.mapAttrsToList (h: k: "${h} ${k}") nixosKnown) + "\n";
  nixosMirroredPins = lib.concatStringsSep "\n" (lib.mapAttrsToList (h: k: "${h} ${k}") nixosMirrored) + "\n";
  hmKnownHosts = if isDarwinHost then "" else hmKnownText;
  allowedSigners = (if isDarwinHost then dHm dOn else hmNixos).home.file.".ssh/allowed_signers".text;
}
