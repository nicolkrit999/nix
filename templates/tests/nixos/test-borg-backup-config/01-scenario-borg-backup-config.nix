let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";

  hosts = {
    desktop = { name = "nixos-desktop"; conf = "desktop-data"; other = "laptop-data"; time = "18:00"; onBattery = false; };
    laptop = { name = "nixos-laptop"; conf = "laptop-data"; other = "desktop-data"; time = "10:00"; onBattery = true; };
  };

  asList = v: if builtins.isList v then v else [ v ];
  persistDirs = c: map (d: d.directory or d) c.environment.persistence."/persist".directories;
  failingWith = needle: c: lib.filter (a: lib.hasInfix needle a.message) (lib.filter (a: !a.assertion) c.config.assertions);

  duplicates = l: lib.filter (x: lib.count (y: y == x) l > 1) (lib.unique l);
  typoed = lib.filter (p: lib.hasInfix "clouflared" p);
  edgeWs = lib.filter (p: p != lib.trim p);
  quote = l: lib.concatMapStringsSep ", " (p: "\"${p}\"") l;

  selftestList = [ "/home/*/ok" "/home/*/dotfiles " " /home/*/lead" "/home/*/.clouflared" "/dup" "/dup" ];

  mk = key:
    let
      h = hosts.${key};
      cfg = flake.nixosConfigurations.${h.name}.config;
      cfg' = { config = cfg; };
      bm = cfg.services.borgmatic.configurations;
      c = bm.${h.conf};
      excludes = c.exclude_patterns;
      repo = lib.head c.repositories;
      secrets = cfg.sops.secrets;
      passPath = secrets.borg-passphrase.path;
      keyPath = secrets.borg-private-key.path;
      tokens = lib.splitString " " c.ssh_command;
      nasHost = cfg.myconfig.krit.services.nas.host;
      repoHost = lib.head (lib.splitString "/" (lib.last (lib.splitString "@" repo.path)));
      onCal = asList (cfg.systemd.timers.borgmatic.timerConfig.OnCalendar or [ ]);
      acPower = cfg.systemd.services.borgmatic.unitConfig.ConditionACPower or null;
      sys = flake.nixosConfigurations.${h.name};
      noImperm = (sys.extendModules { modules = [{ myconfig.services.impermanence.enable = lib.mkForce false; }]; }).config;
      emptyPass = sys.extendModules { modules = [{ myconfig.krit.services.nas."${key}-borg-backup".passphraseFile = lib.mkForce ""; }]; };
      emptyKey = sys.extendModules { modules = [{ myconfig.krit.services.nas."${key}-borg-backup".sshKeyPath = lib.mkForce ""; }]; };
      identity = lib.elemAt tokens ((lib.lists.findFirstIndex (t: t == "-i") (-1) tokens) + 1);
    in
    {
      "check-${key}-excludes-no-known-typos" =
        chk (typoed excludes == [ ]) "typo'd exclude patterns: ${quote (typoed excludes)}";
      "check-${key}-excludes-unique" =
        chk (duplicates excludes == [ ]) "duplicate exclude patterns: ${quote (duplicates excludes)}";
      "check-${key}-excludes-no-edge-whitespace" =
        chk (edgeWs excludes == [ ]) "exclude patterns with leading/trailing whitespace: ${quote (edgeWs excludes)}";
      "check-${key}-excludes-unique-after-trim" =
        chk (duplicates (map lib.trim excludes) == [ ]) "exclude patterns duplicate once borgmatic strips whitespace: ${quote (duplicates (map lib.trim excludes))}";
      "check-${key}-excludes-nonempty-no-blank" =
        chk (excludes != [ ] && lib.all (p: lib.trim p != "") excludes) "exclude_patterns empty or has blank entry";
      "check-${key}-passcommand-reads-sops-passphrase" =
        chk (c.encryption_passcommand == "cat ${passPath}" && passPath != "")
          "encryption_passcommand is '${c.encryption_passcommand}', expected 'cat <sops borg-passphrase path>' ('${passPath}')";
      "check-${key}-ssh-identity-is-sops-key" =
        chk (identity == keyPath && keyPath != "" && lib.hasPrefix "/" identity)
          "ssh -i is '${identity}', expected sops borg-private-key path '${keyPath}'";
      "check-${key}-ssh-command-no-empty-args" =
        chk (!(lib.hasInfix "  " c.ssh_command) && c.ssh_command == lib.trim c.ssh_command)
          "ssh_command has doubled or edge whitespace: '${c.ssh_command}'";
      "check-${key}-secrets-declared" =
        chk (secrets ? borg-passphrase && secrets ? borg-private-key) "sops.secrets lacks borg-passphrase or borg-private-key";
      "check-${key}-repo-ends-with-hostname" =
        chk (lib.hasPrefix "ssh://" repo.path && lib.hasSuffix "/${cfg.networking.hostName}" repo.path)
          "repository '${repo.path}' does not end with /${cfg.networking.hostName}";
      "check-${key}-repo-label" = chk (repo.label == "nas-repo") "repository label is '${repo.label}'";
      "check-${key}-source-is-user-home" =
        chk (c.source_directories == [ "/home/${cfg.myconfig.constants.user}" ])
          "source_directories is ${quote c.source_directories}";
      "check-${key}-own-config-only" =
        chk (bm ? ${h.conf} && !(bm ? ${h.other})) "configurations are ${quote (lib.attrNames bm)}, expected only ${h.conf}";
      "check-${key}-timer-persistent" =
        chk (cfg.systemd.timers.borgmatic.timerConfig.Persistent == true) "timer is not Persistent";
      "check-${key}-service-exists" =
        chk (cfg.services.borgmatic.enable && cfg.systemd.services ? borgmatic) "borgmatic service not enabled/defined";
      "check-${key}-timer-resets-packaged-calendar" =
        chk (onCal != [ ] && lib.head onCal == "" && lib.filter (x: x != "") onCal == [ h.time ])
          "OnCalendar is ${builtins.toJSON onCal}, expected [ \"\" \"${h.time}\" ] (empty entry resets the packaged daily)";
      "check-${key}-ac-power-condition" =
        chk (if h.onBattery then acPower == "" else acPower == null)
          "ConditionACPower is ${builtins.toJSON acPower}, expected ${if h.onBattery then "\"\" (reset, laptop runs on battery)" else "no override"}";
      "check-${key}-persists-borgmatic-state" =
        chk (lib.elem "/var/lib/borgmatic" (persistDirs cfg) && !(lib.elem "/var/lib/borgmatic" (persistDirs noImperm)))
          "/var/lib/borgmatic must be persisted with impermanence on and not listed with it off";
      "check-${key}-borg-base-directory" =
        chk (c.borg_base_directory == "/var/lib/borgmatic") "borg_base_directory is '${c.borg_base_directory or "unset"}'";
      "check-${key}-ssh-identities-only-and-pinned" =
        chk (lib.elem "IdentitiesOnly=yes" tokens && !(lib.hasInfix "StrictHostKeyChecking" c.ssh_command))
          "ssh_command must have IdentitiesOnly=yes and no StrictHostKeyChecking override: '${c.ssh_command}'";
      "check-${key}-repo-host-is-nas-fqdn" =
        chk (repoHost == nasHost && lib.hasInfix "." repoHost)
          "repository host '${repoHost}', expected krit.services.nas.host '${nasHost}' (FQDN, matches the pinned host key)";
      "check-${key}-checks-frequency" =
        chk (c.checks != [ ] && lib.all (k: (k.frequency or null) == "2 weeks") c.checks)
          "borgmatic checks without frequency '2 weeks': ${builtins.toJSON c.checks}";
      "check-${key}-excludes-secrets-and-dotfiles-private" =
        chk (lib.all (p: lib.elem p excludes) [ "/home/*/.ssh" "/home/*/dotfiles-private" ] && !(lib.elem "/home/*/wallpapers-repo" excludes))
          "excludes must contain /home/*/.ssh and /home/*/dotfiles-private and not /home/*/wallpapers-repo";
      "check-${key}-empty-secret-path-assertions-fire" =
        chk (failingWith "borg-backup" cfg' == [ ] && lib.length (failingWith "passphraseFile is empty" emptyPass) == 1 && lib.length (failingWith "sshKeyPath is empty" emptyKey) == 1)
          "borg-backup assertions: real host must pass; empty passphraseFile and empty sshKeyPath must each fire exactly once";
      "check-${key}-tailscale-enabled" = chk cfg.services.tailscale.enable "services.tailscale.enable is false";
    };
in
mk "desktop" // mk "laptop" // {
  check-lint-selftest-trimmed-duplicates = chk (duplicates (map lib.trim [ "/a" "/a " " /b" "/b" "/c" ]) == [ "/a" "/b" ]) "trimmed-duplicate lint does not detect planted duplicates";
  check-lint-selftest-edge-whitespace = chk (edgeWs selftestList == [ "/home/*/dotfiles " " /home/*/lead" ]) "edge-whitespace lint does not detect planted entries";
  check-lint-selftest-typo = chk (typoed selftestList == [ "/home/*/.clouflared" ]) "typo lint does not detect planted typo";
  check-lint-selftest-duplicates = chk (duplicates selftestList == [ "/dup" ]) "duplicate lint does not detect planted duplicate";
}
