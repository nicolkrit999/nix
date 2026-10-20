# test-ssh-trust-pins

Guards the SSH host-key pins and Host aliases that the config keeps in two places (NixOS and home-manager), plus the SSH commit-signing wiring on NixOS and on the Darwin host (git signing, NAS pin, no host-key override in the Darwin borg and sshfs paths). A mis-pasted or truncated key otherwise only shows up as a host-key prompt or a failed `git push`. Eval plus `ssh-keygen`, no builds.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-ssh-trust-pins` (name as shown by `--list`); the direct command is below.

From repo root:

```bash
bash templates/tests/nixos/test-ssh-trust-pins/check-nixos-ssh-trust-pins.sh
```

From inside the directory:

```bash
bash check-nixos-ssh-trust-pins.sh
```

`FLAKE_ROOT=<path>` evaluates another copy of the repo. The three hosts evaluate in parallel; 55 s inside the full parallel suite run of 2026-10-11. Runs in the `nixos-b` CI group (`test.conf`). Uses `ssh-keygen` from `PATH`, falling back to `nix shell nixpkgs#openssh`.

## How it works

The repo is public and the test hardcodes no keys or fingerprints. It only compares what the config contains against itself and parses it with `ssh-keygen -lf` at test time.

`01-scenario-ssh-trust-pins.nix` reads the real `nixosConfigurations.<HOST>` (or `darwinConfigurations.<HOST>`), the NixOS-nested home-manager config, and the standalone `homeConfigurations."krit@<HOST>"` (the only place `home.file.".ssh/known_hosts"` exists). `report` is `label<TAB>result` lines (`ok` or `FAIL: ...`). `nixosPins`, `nixosMirroredPins` (all pins minus the NixOS-only `nicol-nas-tailnet`, used for the HM fingerprint comparison), `hmKnownHosts` and `allowedSigners` expose the raw texts for the script. NixOS `extraConfig` is parsed into per-alias option sets and compared with the home-manager `programs.ssh.settings` entries.

The script first runs a parser control: a truncated key must be rejected by `ssh-keygen -lf`, proving the key checks can fail. It then writes each key to a file and runs `ssh-keygen -lf`, checks that the key type field matches the blob type, and compares the fingerprints of the NixOS and HM copies.

## Checks

Per NixOS host (`nixos-desktop`, `nixos-laptop`):

| Check | Expected |
|-------|----------|
| NixOS knownHosts pins a literal key | non-empty, every value is `<type> <blob>` |
| known_hosts line shape | non-empty, every line has exactly 3 fields |
| known_hosts duplicates | no repeated (host, key type) pair |
| NixOS pin appears in HM known_hosts | each NixOS-pinned key is present verbatim for that host; the NixOS-only `nicol-nas-tailnet` pin is exempt on purpose (the standalone-HM `known_hosts` in `ssh-config.nix` does not carry it) |
| HM-only hosts | every non-`github.com` host in HM known_hosts also has a NixOS pin (the NAS pin is not part of the mirror) |
| NixOS pins parse | `ssh-keygen -lf` accepts each, key type matches blob |
| HM known_hosts lines parse | `ssh-keygen -lf` accepts each, key type matches blob |
| Fingerprints equal | `ssh-keygen` fingerprints of NixOS and HM copies are identical (mirrored pins only, i.e. without `nicol-nas-tailnet`) |
| Host alias set | NixOS `extraConfig` aliases equal HM `programs.ssh.settings` aliases |
| Host option values | per alias, `extraConfig` options equal HM settings |
| gateway alias | present in `extraConfig` and HM settings |
| gatewayAlias option | `krit.system.ssh-config.gatewayAlias` option default is `false`, `true` on the real host; a twin with it forced `false` has no `gateway` alias in `extraConfig` or HM settings |
| peer Host entry | the other NixOS host (derived from the host list, never the host itself) has a Host entry in `extraConfig` and HM settings with `HostName` = its tailnet name, `User`, `IdentitiesOnly yes`, `IdentityFile ~/.ssh/id_github` |
| sshd authorized keys | `services.openssh.authorizedKeysFiles` has `%h/.ssh/id_github.pub` (the sops secret path) next to the default files; `authorizedKeys.keys` and `keyFiles` are empty, so no key literal lives in the repo |
| ssh-<peer> alias | `ssh-<peer>` shell alias is `ssh <peer>`, absent for the host itself |
| remote-build aliases | `sw-laptop-with-desktop` and `build-laptop-with-desktop` (`nh os switch/build <flake> --hostname nixos-laptop --build-host krit@nixos-desktop`) exist on the laptop only |
| NAS pin | `programs.ssh.knownHosts."nicol-nas-tailnet"` is an `ssh-ed25519` key equal to `krit.services.nas.hostKey`, for both `nas.host` and `nas.tailnetIp`; `Host nicol-nas` `HostName` equals `nas.host` |
| No host-key bypass | no borgmatic `ssh_command` and no sshfs mount option (sshfs enabled via `extendModules`) contains `StrictHostKeyChecking` |
| Standalone home aliases | aliases (minus `*`) are a subset of the NixOS aliases |
| Standalone `UserKnownHostsFile` | covers `known_hosts` and `known_hosts.local` |
| tmpfiles | `d /home/<user>/.ssh 0700 <user> users -` |
| gnupg agent | enabled with SSH support off |
| git signing | `gpg.format == ssh`, `commit.gpgSign == true`, `allowedSignersFile` set |
| allowed_signers | one `<email> <type> <key>` line; key parses with `ssh-keygen -lf` (the script checks every allowed_signers line, on Darwin two) |

`Krits-MacBook-Pro` (Darwin). The enable switches of the sshfs, borg and git-ssh-signing modules are forced on in an `extendModules` twin, so the checks do not depend on which of them the host enables:

| Check | Expected |
|-------|----------|
| knownHosts pins a literal key | non-empty, `<type> <blob>` |
| Pins parse | `ssh-keygen -lf` accepts each (now including the NAS pin), type matches blob |
| gitea pin | equals the NixOS gitea pin |
| NAS pin | `programs.ssh.knownHosts."nicol-nas-tailnet"` is an `ssh-ed25519` key equal to `krit.services.nas.hostKey` for `nas.host` and `nas.tailnetIp`; the HM `Host nicol-nas` `HostName` equals `nas.host` |
| borg | every repository is `ssh://<nas.user>@<nas.host>/...` with a host in the pin's `hostNames`; `ssh_command` has `IdentitiesOnly=yes` and neither `StrictHostKeyChecking` nor `accept-new` |
| sshfs | the script (comment lines ignored) connects as `@<host>:` to a pinned host and has neither `StrictHostKeyChecking` nor `accept-new` |
| git signing (read from `iniContent`) | `gpg.format == ssh`, `commit.gpgSign` and `tag.gpgSign` true, `user.signingKey` and `allowedSignersFile` under `~/.ssh` of `users.users.<user>.home`; exactly one `gitdir:~/school-workspace/**` include with an email different from the base email and a signing key under `~/.ssh` different from the base key; `allowed_signers` lines are `<principal> ssh-ed25519 <key>`, the first principal is the git `user.email`, the school include's email is also a principal; no `signing.key` and no lowercase `user.signingkey` |
| no mkForce | a twin overriding `signing.signByDefault`, `commit.gpgSign`, `gpg.format`, `user.signingKey` and `gpg.ssh.allowedSignersFile` at priority 90 wins, which a `mkForce` in `git-ssh-signing` would prevent |
| allowed_signers keys parse | `ssh-keygen -lf` accepts both lines (primary and school) |

Darwin controls (all against one broken twin: knownHosts emptied, borg `IdentitiesOnly=yes` replaced by `StrictHostKeyChecking=accept-new`, sshfs script with an `accept-new` option appended, `extraAllowedSigners` emptied, `signByDefault` forced off):

| Control | Expected |
|---------|----------|
| pin | the NAS pin predicate fails on the twin |
| borg | the borg predicate fails on the twin |
| sshfs | the sshfs predicate fails on the twin |
| tag signing | the git predicate reports `tag.gpgSign is not true` (the `signByDefault` lesson from `nixos-spec-school`) |
| school signer | the git predicate reports the missing school principal |
| mkForce detector | in the priority-90 twin a `mkForce`d probe leaf keeps its value while a plain one is overridden, so the "no mkForce" check can fail |

Control:

| Check | Expected |
|-------|----------|
| Truncated key | `ssh-keygen -lf` rejects it |
