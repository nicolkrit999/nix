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

The script writes each script to a temp dir and runs `bash -n` on it. For the two `writeShellScript` derivations it reads the text with `nix derivation show` (no build). Nothing secret is hardcoded: values are compared against each other (sops key path vs `IdentityFile`, git email vs `allowed_signers` principal vs the base host email, hyprland monitor scale vs rendered `uiScale`). The scale is asserted both as the exact rendered string (`toString 1.5` is `1.500000`) and parsed as a float. Controls prove the checks bite: the uiScale parser must reject a different scale, `bash -n` must reject a broken script, and an unquoted command must split into several arguments. The setup script is additionally run in the shell with `distrobox`/`podman` store paths rewritten to stub functions that log their argument count, so quoting regressions of the `bash -c` payloads are caught by behaviour, not text matching.

## Checks

Per host (scenario report):

| Check | Expected |
|-------|----------|
| specialisation evaluates | `specialisation.school` exists, tags `[ "school" ]` |
| constants.shell | `bash` |
| tailscale | `myconfig.services.tailscale.enable`; upstream `tailscaled-autoconnect` exists and the removed repo unit `tailscale-autoconnect` does not |
| exit-node-off unit | `wantedBy multi-user.target`, all `after`/`wants` units exist in `systemd.services`, `After` `tailscaled.service`, never references `tailscale-autoconnect.service` |
| exit-node-off non-blocking | `serviceConfig.Type = "exec"` |
| exit-node-off retry | script retries `tailscale set --exit-node= && exit 0` in a bounded `seq` loop with `timeout`, ends `exit 1`, and does not wait on `BackendState` |
| exit-node-off path | `tailscale` package on the unit `path` |
| ssh | `enableDefaultConfig` off; github.com, gitlab.com, gitlab-edu.supsi.ch use `IdentityFile` equal to `sops.secrets.school_ssh_key.path` and `IdentitiesOnly = yes`; github identity differs from the base host's |
| git signing | `user.email` differs from the base email; `gpg.format = ssh`, `commit.gpgSign` and `signByDefault` on, `tag.gpgSign` true in the effective `iniContent` (home-manager derives it from `signing.signByDefault`, not from `settings`); `user.signingKey` (camelCase) equals the sops school key; no lowercase `user.signingkey` and `signing.key` null; the `git-ssh-signing` options carry the school key and email (email differs from base); `allowedSignersFile` equals home dir plus the `home.file` target |
| allowed_signers | first line principal equals git `user.email` with an ed25519 key; exactly two lines, the second equal to the base (personal) line with a different principal; control: base file does not contain the school principal |
| school secrets | `school_ssh_key` and `school_ssh_pub` declared in the spec (`.pub` path next to the key); absent from the base `sops.secrets` (control) |
| network and capture | NM VPN plugin files `nm-openvpn-service.name` and `nm-openconnect-service.name` in `environment.etc` (control: a made-up plugin name is absent); `programs.wireshark.enable` and the user in `wireshark` |
| PWA entries | every `school-pwa-*` desktop entry has no `mimeType` and categories `[ "Education" ]`; control: the predicate rejects an entry with a mimeType or another category |
| OneDrive unit | `StartLimitIntervalSec` and `StartLimitBurst` set, no `network-online.target` in `After`/`Wants`, `Restart = on-failure` |
| launchers | tkgate and sqldeveloper use the narrow `si:localuser:` xhost entry with grant and revoke, never `xhost +`; `idea-school` exports `GIT_CONFIG_GLOBAL` to `$HOME/.config/git/config`; year directories use `2nd`/`3rd` (no `2st`/`3st`); niri and mango autostart `nvim` |
| davfs | spaces non-empty; one fileSystem per space with `fsType davfs` and `device == url`; options `noauto nofail x-systemd.automount _netdev`; `uid=` equals `myconfig.constants.user` and `gid=` equals the user's primary group name (davfs2 resolves names); davfs2 enabled, secrets linked, user in `davfs2` group; no space path equals `University` |
| scale | `sqldeveloper-school` `uiScale` equals the hyprland monitor scale (exact string and float) and is not the 1.0 fallback (the scale is derived from the enabled monitors); control parser rejects another scale; tkgate `Xft.dpi` is `floor(96 * scale)` |
| scripts | eight school scripts exist; setup creates `school-ubuntu` and `school-arch`; clear names both; launchers enter the matching container; both `check` strings are single-quote-safe in setup |
| workspaces | every `[workspace N` in hyprland `execOnce` is in `monitorWorkspaces` |
| stub-run | the generated `school-distrobox-setup` is run with `distrobox`/`podman` replaced by stubs: exits 0, creates both containers, every `distrobox enter`/`podman exec` gets exactly one command argument (so `escapeShellArg` quoting holds), and the sqldeveloper postInstall (sed plus grep line) arrives as ONE argument |
| bash -n | the eight scripts plus the startup-check and deep-check derivations parse; startup and deep checks name both containers |

Global controls: `bash -n` rejects a deliberately broken script; an unquoted multi-word command splits into several arguments (the stub-run argument count can fail).
