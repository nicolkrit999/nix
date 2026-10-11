let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  chk = cond: msg: if cond then "ok" else "FAIL: ${msg}";

  hosts = {
    desktop = { name = "nixos-desktop"; conf = "desktop-data"; other = "laptop-data"; };
    laptop = { name = "nixos-laptop"; conf = "laptop-data"; other = "desktop-data"; };
  };

  duplicates = l: lib.filter (x: lib.count (y: y == x) l > 1) (lib.unique l);
  typoed = lib.filter (p: lib.hasInfix "clouflared" p);
  edgeWs = lib.filter (p: p != lib.trim p);
  quote = l: lib.concatMapStringsSep ", " (p: "\"${p}\"") l;

  selftestList = [ "/home/*/ok" "/home/*/dotfiles " " /home/*/lead" "/home/*/.clouflared" "/dup" "/dup" ];

  mk = key:
    let
      h = hosts.${key};
      cfg = flake.nixosConfigurations.${h.name}.config;
      bm = cfg.services.borgmatic.configurations;
      c = bm.${h.conf};
      excludes = c.exclude_patterns;
      repo = lib.head c.repositories;
      secrets = cfg.sops.secrets;
      passPath = secrets.borg-passphrase.path;
      keyPath = secrets.borg-private-key.path;
      tokens = lib.splitString " " c.ssh_command;
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
      "check-${key}-tailscale-enabled" = chk cfg.services.tailscale.enable "services.tailscale.enable is false";
    };
in
mk "desktop" // mk "laptop" // {
  check-lint-selftest-trimmed-duplicates = chk (duplicates (map lib.trim [ "/a" "/a " " /b" "/b" "/c" ]) == [ "/a" "/b" ]) "trimmed-duplicate lint does not detect planted duplicates";
  check-lint-selftest-edge-whitespace = chk (edgeWs selftestList == [ "/home/*/dotfiles " " /home/*/lead" ]) "edge-whitespace lint does not detect planted entries";
  check-lint-selftest-typo = chk (typoed selftestList == [ "/home/*/.clouflared" ]) "typo lint does not detect planted typo";
  check-lint-selftest-duplicates = chk (duplicates selftestList == [ "/dup" ]) "duplicate lint does not detect planted duplicate";
}
