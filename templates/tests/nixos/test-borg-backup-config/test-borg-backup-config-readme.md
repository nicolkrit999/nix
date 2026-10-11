# test-borg-backup-config

Evaluates the real `nixos-desktop` and `nixos-laptop` hosts and asserts their borgmatic backup config: exclude-list hygiene, sops wiring of passphrase and SSH key, repository path, persistent timer, service and tailscale. Host choices (e.g. the timer's OnCalendar time) are deliberately not asserted.

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
| source-is-user-home | `source_directories == [ "/home/<constants.user>" ]` |
| own-config-only | only this host's configuration key exists (`desktop-data` / `laptop-data`) |
| timer-persistent | timer is `Persistent` |
| service-exists | `services.borgmatic.enable` and `systemd.services.borgmatic` defined |
| tailscale-enabled | `services.tailscale.enable` |

### lint self-test
| Check | Expected |
|-------|----------|
| lint-selftest-typo / duplicates / trimmed-duplicates / edge-whitespace | each lint flags exactly the planted bad entries |
