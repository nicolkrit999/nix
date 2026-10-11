# test-spec-school

Checks the `school` specialisation (`users/krit/nixos/specializations/school.nix`) on the real `nixos-desktop` and `nixos-laptop`: isolated SSH and git identity, self-contained davfs mounts, forced tailscale, HiDPI scale and the generated distrobox scripts. Eval only, no builds.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-spec-school` (name as shown by `--list`); the direct command is below.

From repo root:

```bash
bash templates/tests/nixos/test-spec-school/check-nixos-spec-school.sh
```

From inside the directory:

```bash
bash check-nixos-spec-school.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo. Both hosts evaluate in parallel; 54 s inside the full parallel suite run of 2026-10-11.

## How it works

`01-scenario-spec-school.nix` reads the real `nixosConfigurations.<HOST>` (`HOST` env var) and its `specialisation.school` config. `report` is one `label<TAB>result` line per check (`ok` or `FAIL: <detail>`). `scripts` is the JSON text of the generated `writeShellScriptBin` scripts; `drvs` lists the `writeShellScript` derivations (startup check, deep check) found in the string context of `programs.bash.initExtra` and the check script.

The script writes each script to a temp dir and runs `bash -n` on it. For the two `writeShellScript` derivations it reads the text with `nix derivation show` (no build). Nothing secret is hardcoded: values are compared against each other (sops key path vs `IdentityFile`, git email vs `allowed_signers` principal vs the base host email, hyprland monitor scale vs rendered `uiScale`). The scale is asserted both as the exact rendered string (`toString 1.5` is `1.500000`) and parsed as a float. Two controls prove the checks bite: the uiScale parser must reject a different scale, and `bash -n` must reject a broken script.

## Checks

Per host (scenario report):

| Check | Expected |
|-------|----------|
| specialisation evaluates | `specialisation.school` exists, tags `[ "school" ]` |
| constants.shell | `bash` |
| tailscale | `myconfig.services.tailscale.enable`, `tailscale-autoconnect` service exists |
| exit-node-off unit | `wantedBy multi-user.target`, all `after`/`wants` units exist in `systemd.services`, stays `After`/`Wants` `tailscale-autoconnect.service` |
| exit-node-off non-blocking | `serviceConfig.Type = "exec"` |
| exit-node-off retry | script retries `tailscale set --exit-node= && exit 0` in a bounded `seq` loop with `timeout`, ends `exit 1`, and does not wait on `BackendState` |
| exit-node-off path | `tailscale` package on the unit `path` |
| ssh | `enableDefaultConfig` off; github.com, gitlab.com, gitlab-edu.supsi.ch use `IdentityFile` equal to `sops.secrets.school_ssh_key.path` and `IdentitiesOnly = yes`; github identity differs from the base host's |
| git | email differs from base and matches the `allowed_signers` principal (ed25519); `gpg.format = ssh`; signing on; signing key is the sops school key; `allowedSignersFile` equals home dir plus the `home.file` target |
| davfs | spaces non-empty; one fileSystem per space with `fsType davfs` and `device == url`; options `noauto nofail x-systemd.automount _netdev`; `uid=` equals `myconfig.constants.user` and `gid=` equals the user's primary group name (davfs2 resolves names); davfs2 enabled, secrets linked, user in `davfs2` group; no space path equals `University` |
| scale | `sqldeveloper-school` `uiScale` equals the hyprland monitor scale (exact string and float); control parser rejects another scale; tkgate `Xft.dpi` is `floor(96 * scale)` |
| scripts | eight school scripts exist; setup creates `school-ubuntu` and `school-arch`; clear names both; launchers enter the matching container; both `check` strings are single-quote-safe in setup |
| workspaces | every `[workspace N` in hyprland `execOnce` is in `monitorWorkspaces` |
| bash -n | the eight scripts plus the startup-check and deep-check derivations parse; startup and deep checks name both containers |

Global: `bash -n` rejects a deliberately broken script (control).
