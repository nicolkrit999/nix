# test-host-invariants

Asserts boot and lockout invariants on the REAL `nixos-desktop` and `nixos-laptop` configurations (impermanence, sops host key, bootloader, password wiring, tailscale base, home-manager wiring).

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-host-invariants` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-host-invariants/check-nixos-host-invariants.sh
```

Or from inside the directory:

```bash
bash check-nixos-host-invariants.sh
```

## How it works

`01-scenario-host-invariants.nix` loads the real flake (`builtins.getFlake`, root overridable with `FLAKE_ROOT`) and reads `nixosConfigurations.$HOST_UNDER_TEST.config`. It returns an attrset of checks, each `"ok"` or `"FAIL: <detail>"`; every check is wrapped in `tryEval`, so a missing option becomes a FAIL instead of aborting.

`check-nixos-host-invariants.sh` runs one `nix eval --json --impure` per host, prints a PASS/FAIL line per check and exits non-zero on any failure. Eval only, no builds. No secret values are embedded: checks compare config values against each other (e.g. the sops key dir against persisted directories).

Scope: only safety contracts and cross-file consistency are asserted; host choices (kernel flavour, kernel patches, which power daemon a laptop picks) are deliberately not tested. No fake host is used.

Notes: `constants.emergencyAccess` is intentionally `true` on both hosts (snapshot check) and must be wired to `boot.initrd.systemd.emergencyAccess`. `nix.gc.automatic` is deliberately not asserted here (owned by another test).

## Checks

Per host unless marked.

| Check | Expected |
|-------|----------|
| hostname | `networking.hostName == constants.hostname == host name` |
| user | `constants.user == "krit"` |
| emergency-access-snapshot | `constants.emergencyAccess == true` |
| emergency-access-wired | `boot.initrd.systemd.emergencyAccess == constants.emergencyAccess` |
| impermanence-enabled | `myconfig.services.impermanence.enable` |
| root-tmpfs | `fileSystems."/".fsType == "tmpfs"` |
| persist / var-log needed-for-boot | both `neededForBoot` |
| persist-dirs | `/etc/ssh`, `/var/lib/nixos`, `/var/lib/tailscale`, `/var/lib/systemd/timesync`, `/var/lib/NetworkManager` persisted |
| borgmatic-state-persisted | if `services.borgmatic` is enabled, `/var/lib/borgmatic` is a persisted directory (whether a host enables borgmatic is not asserted; `test-borg-backup-config` also checks the impermanence-off twin) |
| persist-machine-id / random-seed-not-persisted | `/etc/machine-id` persisted file; `/var/lib/systemd/random-seed` must NOT be persisted (live switch fails: file already exists) |
| resolved-no-global-domains | `services.resolved.settings.Resolve.Domains` does not contain `~.` |
| resolved-mdns-off-with-avahi | `extendModules` twins: avahi forced on gives `MulticastDNS = "false"`, avahi forced off does not |
| luks-cryptroot (laptop) | all btrfs mounts on `/dev/mapper/cryptroot`, luks device `cryptroot` exists |
| desktop-no-luks (desktop) | no LUKS devices (premise of emergencyAccess) |
| sops-key-persisted | every `sops.age.sshKeyPaths` entry under `/persist/` |
| sops-key-matches-persisted-ssh | the key's directory is itself a persisted directory |
| password-secret-for-users | `krit-local-password.neededForUsers` |
| immutable-users | `users.mutableUsers == false` |
| password-files | krit and root `hashedPasswordFile` = the sops secret path |
| bootloader | grub on, systemd-boot off, no EFI var writes, removable install, device `nodev` |
| btrfs-autoscrub | `services.btrfs.autoScrub` is enabled with exactly one existing btrfs mount point per btrfs device; a twin with every filesystem forced to ext4 has it disabled |
| default-locale-from-constants | `i18n.defaultLocale == constants.mainLocale`; a twin with a different `mainLocale` follows it |
| nix-pat-include | `nix.extraOptions` includes the PAT file under `/run/secrets` |
| pat-secret-declared | sops secret exists and resolves to that path |
| one-sddm-theme | exactly one of sddm-astronaut / sddm-pixie enabled |
| power-exclusive | at most one of auto-cpufreq/tlp enabled (conflict) |
| tailscale-trusted / reverse-path | `tailscale0` trusted, `checkReversePath == "loose"` |
| tailscale-operator | `--operator=<user>` in up/set flags |
| tailscale-authkey-sops | `services.tailscale.authKeyFile` is the path of the sops secret `tailscale_key`, owned by root (`owner = "root"`, or `owner = null` with `uid = 0`) with mode `0400` (login runs through upstream `tailscaled-autoconnect`) |
| hm-use-global-pkgs-pinned | `home-manager.useGlobalPkgs == false` (deliberate pin, see the xdg-desktop-portal gotcha doc) |
| hm-use-user-packages | `home-manager.useUserPackages == true` |
| hm-plasma-manager-loaded | `home-manager.users.<user>.programs.plasma` is declared (plasma-manager reaches HM on NixOS; Darwin's HM lacks it, so the probe discriminates) |
| no-failing-assertions | `config.assertions` has no failing entry |
