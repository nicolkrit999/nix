# test-ssh-trust-pins

Guards the SSH host-key pins and Host aliases that the config keeps in two places (NixOS and home-manager), plus the SSH commit-signing wiring. A mis-pasted or truncated key otherwise only shows up as a host-key prompt or a failed `git push`. Eval plus `ssh-keygen`, no builds.

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

`01-scenario-ssh-trust-pins.nix` reads the real `nixosConfigurations.<HOST>` (or `darwinConfigurations.<HOST>`), the NixOS-nested home-manager config, and the standalone `homeConfigurations."krit@<HOST>"` (the only place `home.file.".ssh/known_hosts"` exists). `report` is `label<TAB>result` lines (`ok` or `FAIL: ...`). `nixosPins`, `hmKnownHosts` and `allowedSigners` expose the raw texts for the script. NixOS `extraConfig` is parsed into per-alias option sets and compared with the home-manager `programs.ssh.settings` entries.

The script first runs a parser control: a truncated key must be rejected by `ssh-keygen -lf`, proving the key checks can fail. It then writes each key to a file and runs `ssh-keygen -lf`, checks that the key type field matches the blob type, and compares the fingerprints of the NixOS and HM copies.

## Checks

Per NixOS host (`nixos-desktop`, `nixos-laptop`):

| Check | Expected |
|-------|----------|
| NixOS knownHosts pins a literal key | non-empty, every value is `<type> <blob>` |
| known_hosts line shape | non-empty, every line has exactly 3 fields |
| known_hosts duplicates | no repeated (host, key type) pair |
| NixOS pin appears in HM known_hosts | each NixOS-pinned key is present verbatim for that host |
| HM-only hosts | every non-`github.com` host in HM known_hosts also has a NixOS pin |
| NixOS pins parse | `ssh-keygen -lf` accepts each, key type matches blob |
| HM known_hosts lines parse | `ssh-keygen -lf` accepts each, key type matches blob |
| Fingerprints equal | `ssh-keygen` fingerprints of NixOS and HM copies are identical |
| Host alias set | NixOS `extraConfig` aliases equal HM `programs.ssh.settings` aliases |
| Host option values | per alias, `extraConfig` options equal HM settings |
| gateway alias | present in `extraConfig` and HM settings |
| Standalone home aliases | aliases (minus `*`) are a subset of the NixOS aliases |
| Standalone `UserKnownHostsFile` | covers `known_hosts` and `known_hosts.local` |
| tmpfiles | `d /home/<user>/.ssh 0700 <user> users -` |
| gnupg agent | enabled with SSH support off |
| git signing | `gpg.format == ssh`, `commit.gpgSign == true`, `allowedSignersFile` set |
| allowed_signers | one `<email> <type> <key>` line; key parses with `ssh-keygen -lf` |

`Krits-MacBook-Pro` (Darwin):

| Check | Expected |
|-------|----------|
| knownHosts pins a literal key | non-empty, `<type> <blob>` |
| Pins parse | `ssh-keygen -lf` accepts each, type matches blob |
| gitea pin | equals the NixOS gitea pin |

Control:

| Check | Expected |
|-------|----------|
| Truncated key | `ssh-keygen -lf` rejects it |
