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
      let missing = lib.filter (h: !(builtins.elem nixosKnown.${h} (hmKeysFor h))) (lib.attrNames nixosKnown); in
      expect "copies" (missing == [ ]) "NixOS key not in HM known_hosts (or differs) for: ${show missing}";
    "every non-github.com host pinned in HM known_hosts has a NixOS knownHosts entry" =
      let
        hmHosts = lib.unique (map (l: lib.head (fields l)) hmKnownLines);
        unpinned = lib.filter (h: !(nixosKnown ? ${h}) && !(lib.hasSuffix "github.com" h)) hmHosts;
      in
      expect "reverse" (unpinned == [ ]) "HM pins hosts with no NixOS pin: ${show unpinned}";
  };

  nixosOnlyChecks = {
    "Host alias set: NixOS extraConfig == HM programs.ssh.settings" =
      expect "aliases" (aliasesOf extra == aliasesOf hmSettings)
        "extraConfig=${show (aliasesOf extra)} hm=${show (aliasesOf hmSettings)}";
    "Host option values: NixOS extraConfig == HM settings, per alias" =
      let
        norm = s: lib.mapAttrs (_: v: toString v) (plain s);
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

  darwinChecks = {
    "knownHosts pins at least one host with a literal key" = commonChecks."NixOS knownHosts pins at least one host with a literal key";
  };

  nixosGiteaKey = flake.nixosConfigurations.nixos-desktop.config.programs.ssh.knownHosts."gitea-ssh.nicolkrit.ch".publicKey;
  darwinCheck = {
    "Darwin gitea pin equals the NixOS gitea pin" =
      expect "darwin-vs-nixos" (nixosKnown."gitea-ssh.nicolkrit.ch" == nixosGiteaKey)
        "darwin=${show (nixosKnown."gitea-ssh.nicolkrit.ch" or null)} nixos=${show nixosGiteaKey}";
  };

  final = if isDarwinHost then darwinChecks // darwinCheck else commonChecks // nixosOnlyChecks;
in
{
  report = lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "${k}\t${v}") final) + "\n";
  nixosPins = lib.concatStringsSep "\n" (lib.mapAttrsToList (h: k: "${h} ${k}") nixosKnown) + "\n";
  hmKnownHosts = if isDarwinHost then "" else hmKnownText;
  allowedSigners = if isDarwinHost then "" else hmNixos.home.file.".ssh/allowed_signers".text;
}
