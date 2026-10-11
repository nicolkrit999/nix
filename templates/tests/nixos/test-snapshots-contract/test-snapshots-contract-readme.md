# test-snapshots-contract

Contract between the snapper configs declared by `services.snapshots` and the `snap-*` helper scripts (`snapshot-functions.nix`) that address them by name. Eval only, no builds.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-snapshots-contract` (name as shown by `--list`); the direct command is below.

From repo root:

```bash
bash templates/tests/nixos/test-snapshots-contract/check-nixos-snapshots-contract.sh
```

From inside the directory:

```bash
bash check-nixos-snapshots-contract.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo. Both hosts evaluate in parallel; 39 s inside the full parallel suite run of 2026-10-11.

## How it works

`01-scenario-snapshots-contract.nix` reads the real `nixosConfigurations.<HOST>` (`HOST` env var) and runs the same checks twice: on the base config (impermanence on, as on both hosts) and on an `extendModules` variant with `myconfig.services.impermanence.enable = mkForce false`. The variant is the control: with the root config named `root` the script-literal check must pass, proving the check can only fail on a real name mismatch. `report` is one `label<TAB>result` line per check (`ok` or `FAIL: <detail>`).

Script text is read from the `text` attribute of the HM `home.packages` derivations (no build). Literals `snapper -c <lit>`, `CFG="<lit>"` and `_snap-create <lit>` are extracted by regex and compared with the keys of `services.snapper.configs`. The `scripts` attribute exports the script texts as JSON; the shell writes them out and runs `bash -n` on each.

## Checks

Per host, for both the base config and the impermanence-off variant:

| Check | Expected |
|-------|----------|
| config keys | base: `home` and `persist`; variant: `home` and `root` |
| root-side SUBVOLUME | base: `/persist`; variant: `/` |
| ALLOW_USERS | `[ myconfig.constants.user ]` on every config |
| TIMELINE_LIMIT_* | all five limits on every config are numeric strings |
| activation text | contains `btrfs subvolume create <dir>/.snapshots` (`/persist/.snapshots` or `/.snapshots`) |
| helper scripts installed | HM packages contain `snap-lock`, `snap-unlock`, `snap-create-home`, `snap-create-root` |
| script literals | every config name literal in those scripts is a key of `services.snapper.configs` |
| scripts have text | each script derivation exposes non-empty text |

Per host, base scripts only:

| Check | Expected |
|-------|----------|
| `bash -n` | `snap-lock`, `snap-unlock`, `snap-create-home`, `snap-create-root` parse |

## History

Before the `snapper` persist-name fix, `snap-lock`, `snap-unlock` and `snap-create-root` hard-coded `root` while the impermanence config is named `persist`, so the "script literals" check failed on the base config of both hosts (the variant passed). `snapshot-functions.nix` now builds the scripts with `mkScripts rootConfigName`, so the literals follow the real config name and the check passes on both configs.
