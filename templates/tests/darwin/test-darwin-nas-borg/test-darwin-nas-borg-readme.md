# test-darwin-nas-borg

Eval-only contract for the NAS wiring of the REAL `darwinConfigurations.Krits-MacBook-Pro`: NAS constants and host-key pin, the borgmatic config (repository URL, secret excludes, strict host-key policy, schedule) and the nix-darwin activation script text. The Mac is CI-only, so nothing here runs on hardware.

Covers gap E-13a. The activation checks target the bug class where a custom `system.activationScripts.<name>` is never spliced by nix-darwin: the mkdir/chown lines must sit in `postActivation`. NOT covered: that the mounts, borg run or ssh pin actually work on a Mac (no hardware; the module comments list the unverified points). `opencloud` and `sshfs` are disabled on the host, so their mkdir lines are only covered through a control that force-enables them via `extendModules`.

## Run

From the repo root:

```bash
bash templates/tests/darwin/test-darwin-nas-borg/check-darwin-nas-borg.sh
```

Or through the runner: `bash templates/tests/run-tests.sh --only darwin-nas-borg`.

From inside the directory:

```bash
bash check-darwin-nas-borg.sh
```

Runtime is well under a minute (lazy eval, no builds).

## How it works

`01-scenario-darwin-nas-borg.nix` loads the real flake (`FLAKE_ROOT`, default `/home/krit/nix`) and reads `darwinConfigurations.Krits-MacBook-Pro`, so config fixes are verified without a rebuild. Each `check-*` attribute is `"ok"` or `"FAIL: ..."`. `check-darwin-nas-borg.sh` runs `nix eval --raw --impure` per check and exits non-zero on any failure.

`hasLine` matches whole lines of the `postActivation` text, so `mkdir -p <mountRoot>/smb` is not satisfied by a longer path. The smb-disabled control proves the line check bites. The host-key-policy predicate also has a self-test against an `accept-new` string. No key or fingerprint is hardcoded: the pin is compared to `nas.hostKey`, only its `ssh-ed25519 ` prefix is checked.

## Checks

### NAS constants and host-key pin

| Check | Expected |
|-------|----------|
| `check-mount-root` | krit.services.nas.mountRoot on darwin |
| `check-nas-user` | krit.services.nas.user (NAS-side account) |
| `check-nas-host-fqdn` | krit.services.nas.host is a dotted FQDN, not a short alias |
| `check-known-hosts-pin` | programs.ssh.knownHosts.nicol-nas-tailnet pins host + tailnetIp with nas.hostKey |
| `check-host-key-shape` | nas.hostKey is a non-empty ssh-ed25519 public key line |

### borgmatic repository and excludes

| Check | Expected |
|-------|----------|
| `check-repo-url` | borgmatic repository path = ssh://<nas.user>@<nas.host>/<dir>/<hostName> |
| `check-repo-single` | borgmatic has exactly one repository |
| `check-source-home` | borgmatic source_directories |
| `check-excludes-secrets` | exclude_patterns hold .ssh, .config/sops, dotfiles-private |
| `check-excludes-control` | control: dropping .ssh from the list is detected |

### ssh host-key policy and credentials

| Check | Expected |
|-------|----------|
| `check-ssh-command-strict` | borgmatic ssh_command has no StrictHostKeyChecking / accept-new / UserKnownHostsFile override |
| `check-no-accept-new-anywhere` | no accept-new / StrictHostKeyChecking in the whole borgmatic config or agent |
| `check-ssh-policy-control` | control: the host-key-policy predicate flags an accept-new ssh_command |
| `check-ssh-identity` | ssh_command uses the sops borg-private-key path with IdentitiesOnly |
| `check-passcommand` | encryption_passcommand reads the sops borg-passphrase path |

### launchd agent

| Check | Expected |
|-------|----------|
| `check-schedule` | StartCalendarInterval is 10:00, 14:00, 22:00 |
| `check-no-run-at-load` | borgmatic agent has no RunAtLoad (a rebuild must not trigger a full backup) |
| `check-agent-config-path` | agent ProgramArguments --config points at the generated /etc file |

### activation script

| Check | Expected |
|-------|----------|
| `check-smb-mkdir-in-activation` | postActivation (the only spliced slot) holds the smb mkdir and chown lines |
| `check-smb-mkdir-control` | control: with smb disabled the smb mkdir line disappears |
| `check-other-shares-mkdir` | control: enabling opencloud + sshfs puts their mkdir lines into postActivation |

### assertions

| Check | Expected |
|-------|----------|
| `check-tailscale-assertion` | no failing assertions (tailnet provider present for the NAS modules) |
