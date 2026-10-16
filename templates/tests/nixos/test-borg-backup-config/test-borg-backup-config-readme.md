# test-borg-backup-config

Evaluates the real `nixos-desktop` and `nixos-laptop` hosts and asserts their borgmatic backup config: exclude-list hygiene, sops wiring of passphrase and SSH key, repository path, persistent timer, timer-calendar reset, AC-power condition, persisted borg state, SSH hardening, NAS FQDN, check frequency and the empty-secret-path assertions, service and tailscale. Which hosts enable borgmatic is not asserted; the per-host backup time (`18:00` desktop, `10:00` laptop) is asserted only as the contract of the OnCalendar reset (an empty first entry cancels the packaged `daily`).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-borg-backup-config` (name as shown by `--list`).

From repo root:

```bash
bash templates/tests/nixos/test-borg-backup-config/check-nixos-borg-backup-config.sh
```

From inside the directory:

```bash
bash check-nixos-borg-backup-config.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo; by default it is derived from the script location. Runtime is a few seconds (one eval, no builds).

## How it works

`01-scenario-borg-backup-config.nix` reads `nixosConfigurations.<host>.config` for both hosts and exposes every check as `"ok"` or `"FAIL: <detail>"`. The script evaluates the whole scenario once as JSON and prints one PASS/FAIL line per check, exiting non-zero on any failure.

Wiring checks compare two independent sources (the rendered `encryption_passcommand` / `ssh -i` path against `sops.secrets.<name>.path`), so no secret or key path is hardcoded in the test.

Exclude patterns are deliberately NOT required to start with `/`: borg strips a leading path separator from `fm:`/`sh:` patterns and stores archive paths without a leading `/`, so `home/*/x` and `/home/*/x` are equivalent. Whether a pattern really matches is a runtime question (`borgmatic create --dry-run --list`), not covered here.

The `lint-selftest-*` checks run the same lint functions on a planted bad list, proving the lints can fail.

Edge whitespace in exclude patterns is flagged as a tidiness check, not a runtime defect: borgmatic strips every entry and borg trims each patterns-file line, so a stray space has no runtime effect, but the config is tidied anyway. Duplicates are checked both raw and after trimming.

Known real findings (fixed in config, not by this test): the `.clouflared` typo and the `"/home/*/dotfiles "` trailing space.

## Checks

Each row exists once per host (`desktop-` / `laptop-` prefix).

| Check | Expected |
|-------|----------|
| excludes-no-known-typos | no entry contains `clouflared` |
| excludes-unique | no duplicate entries |
| excludes-no-edge-whitespace | no entry has leading/trailing whitespace |
| excludes-unique-after-trim | no duplicates once every entry is trimmed (as borgmatic does) |
| excludes-nonempty-no-blank | list non-empty, no blank entry |
| passcommand-reads-sops-passphrase | `encryption_passcommand == "cat " + sops.secrets.borg-passphrase.path` |
| ssh-identity-is-sops-key | the `-i` argument equals `sops.secrets.borg-private-key.path` and is absolute |
| ssh-command-no-empty-args | no doubled/edge whitespace in `ssh_command` |
| secrets-declared | `sops.secrets` has `borg-passphrase` and `borg-private-key` |
| repo-ends-with-hostname | repository is `ssh://...` and ends with `/<networking.hostName>` |
| repo-label | label `nas-repo` |
| sources-are-user-home-and-persist | `source_directories == [ "/home/<constants.user>" "/persist" ]` |
| persist-excludes | `/persist` is a source and the six excludes (`/persist/.snapshots`, `var/lib/{docker,containers,flatpak}`, `var/tmp`, `var/cache/fscache` under `/persist`) are all in `exclude_patterns` |
| own-config-only | only this host's configuration key exists (`desktop-data` / `laptop-data`) |
| timer-persistent | timer is `Persistent` |
| timer-resets-packaged-calendar | `OnCalendar` head is `""` followed by exactly one non-empty entry (`18:00` desktop / `10:00` laptop) |
| ac-power-condition | laptop: `systemd.services.borgmatic.unitConfig.ConditionACPower == ""`; desktop: no override |
| persists-borgmatic-state | `/var/lib/borgmatic` is persisted with impermanence on and absent on an impermanence-off twin |
| borg-base-directory | borgmatic `borg_base_directory == "/var/lib/borgmatic"` |
| ssh-identities-only-and-pinned | `ssh_command` has `IdentitiesOnly=yes` and no `StrictHostKeyChecking` option |
| repo-host-is-nas-fqdn | repository host equals `myconfig.krit.services.nas.host` and contains a dot (not the bare alias) |
| checks-frequency | every borgmatic check has `frequency = "2 weeks"` |
| excludes-secrets-and-dotfiles-private | excludes contain `/home/*/.ssh` and `/home/*/dotfiles-private`, not `/home/*/wallpapers-repo` |
| empty-secret-path-assertions-fire | no borg-backup assertion fails on the real host; forcing `passphraseFile` / `sshKeyPath` to `""` (extendModules) fires exactly one assertion each |
| service-exists | `services.borgmatic.enable` and `systemd.services.borgmatic` defined |
| tailscale-enabled | `services.tailscale.enable` |

### lint self-test
| Check | Expected |
|-------|----------|
| lint-selftest-typo / duplicates / trimmed-duplicates / edge-whitespace | each lint flags exactly the planted bad entries |
