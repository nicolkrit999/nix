# test-host-invariants

Asserts boot and lockout invariants on the REAL `nixos-desktop` and `nixos-laptop` configurations (impermanence, sops host key, bootloader (GRUB or lanzaboote, depending on `services.lanzaboote`), password wiring, tailscale base, home-manager wiring).

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

`check-nixos-host-invariants.sh` runs one `nix eval --json --impure` per host, prints a PASS/FAIL line per check and exits non-zero on any failure. Eval plus one small build per host (`i18n.glibcLocales`, taken from the same eval as a `drvPath`, no second host evaluation). No secret values are embedded: checks compare config values against each other (e.g. the sops key dir against persisted directories).

Scope: only safety contracts and cross-file consistency are asserted; host choices (kernel flavour, kernel patches, which power daemon a laptop picks) are deliberately not tested. No fake host is used.

Notes: `constants.emergencyAccess` is intentionally `false` on both hosts (snapshot check: an initrd root shell defeats Secure Boot) and must be wired to `boot.initrd.systemd.emergencyAccess`; a host with `services.lanzaboote.secureBoot = true` must additionally have it off. Whether a host sets `secureBoot` is not asserted. `nix.gc.automatic` is deliberately not asserted here (owned by another test).

## Checks

Per host unless marked.

| Check | Expected |
|-------|----------|
| hostname | `networking.hostName == constants.hostname == host name` |
| user | `constants.user == "krit"` |
| emergency-access-off | `constants.emergencyAccess == false` on every host |
| emergency-access-wired | `boot.initrd.systemd.emergencyAccess == constants.emergencyAccess` |
| secure-boot-no-emergency-access | a host with `services.lanzaboote.secureBoot = true` has `boot.initrd.systemd.emergencyAccess` off (passes trivially on a host without `secureBoot`) |
| secure-boot-no-emergency-access-control | the rule, applied to synthetic inputs, rejects only `secureBoot` together with `emergencyAccess` |
| impermanence-enabled | `myconfig.services.impermanence.enable` |
| root-tmpfs | `fileSystems."/".fsType == "tmpfs"` |
| persist / var-log needed-for-boot | both `neededForBoot` |
| home-needed-for-boot-base | `/home` is a separate non-tmpfs mount and `neededForBoot` (else user setup creates `/home/<user>` on the throwaway tmpfs root before the real `/home` is mounted over it, and a newly added user ends up with a root-owned home) |
| home-needed-for-boot-specialisations | every specialisation of the host (all of `config.specialisation`, via `configuration.config or configuration`) has a separate `/home` with `neededForBoot` |
| home-needed-for-boot-extra-users | tmpfs `/`, separate `/home` and a normal user besides `constants.user` (specialisation school/guest) requires `/home` `neededForBoot`; at least one specialisation with an extra normal user must exist (not vacuous) |
| home-needed-for-boot-control | the same rules fail on an `extendModules` twin with `/home` `neededForBoot = mkForce false` (base and a specialisation with an extra user) and on synthetic inputs; a tmpfs `/home/guest` alone never triggers them |
| persist-dirs | `/etc/ssh`, `/var/lib/nixos`, `/var/lib/tailscale`, `/var/lib/systemd/timesync`, `/var/lib/NetworkManager` persisted |
| borgmatic-state-persisted | if `services.borgmatic` is enabled, `/var/lib/borgmatic` is a persisted directory (whether a host enables borgmatic is not asserted; `test-borg-backup-config` also checks the impermanence-off twin) |
| persist-machine-id / random-seed-not-persisted | `/etc/machine-id` persisted file; `/var/lib/systemd/random-seed` must NOT be persisted (live switch fails: file already exists) |
| resolved-no-global-domains | `services.resolved.settings.Resolve.Domains` does not contain `~.` |
| resolved-mdns-off-with-avahi | `extendModules` twins: avahi forced on gives `MulticastDNS = "false"`, avahi forced off does not |
| luks-cryptroot (laptop) | all btrfs mounts on `/dev/mapper/cryptroot`, luks device `cryptroot` exists |
| sops-key-persisted | every `sops.age.sshKeyPaths` entry under `/persist/` |
| sops-key-matches-persisted-ssh | the key's directory is itself a persisted directory |
| password-secret-for-users | `krit-local-password.neededForUsers` |
| immutable-users | `users.mutableUsers == false` |
| password-files | krit and root `hashedPasswordFile` = the sops secret path |
| bootloader | systemd-boot off and no EFI var writes on every host; then by `myconfig.services.lanzaboote.enable`: off = grub on, removable install, device `nodev`, lanzaboote off; on = grub off, lanzaboote on, `boot.lanzaboote.pkiBundle` under `/persist/`, `configurationLimit` equal to the host's `myconfig.services.lanzaboote.configurationLimit` and within 1..15, `autoGenerateKeys`/`autoEnrollKeys`/`measuredBoot` all off (which branch a host takes is not asserted) |
| bootloader-control | the same rule, applied to synthetic configs, accepts a good grub and a good lanzaboote config and rejects every single-field mutation of them (grub options, systemd-boot, EFI var writes, lanzaboote on/off, `pkiBundle` outside `/persist/` or under the `/persistent/` prefix trap, a limit different from the option (either side) or outside 1..15 (16 and 0), the three key options, mismatched lanzaboote flag), and accepts limit 5 as well as 10 |
| btrfs-autoscrub | `services.btrfs.autoScrub` is enabled with exactly one existing btrfs mount point per btrfs device; a twin with every filesystem forced to ext4 has it disabled |
| default-locale-from-constants | `i18n.defaultLocale == constants.mainLocale`; a twin with a different `mainLocale` follows it |
| locale-categories | `i18n.extraLocaleSettings`: `LC_ADDRESS`, `LC_IDENTIFICATION`, `LC_MEASUREMENT`, `LC_MONETARY`, `LC_NAME`, `LC_NUMERIC`, `LC_PAPER`, `LC_TELEPHONE` are `it_CH.UTF-8` and `LC_TIME` is the bare `en_IN` (the `services.locale` host values; the bare spelling is the one glibc accepts, nixpkgs#256688) |
| locale-default | `i18n.defaultLocale == "en_US.UTF-8"` (language and messages) |
| locale-display-manager-time | `systemd.services.display-manager.environment.LC_TIME == "en_IN"` |
| locale-time-consistent | `services.locale` is enabled and `services.locale.time`, `extraLocaleSettings.LC_TIME` and the display-manager `LC_TIME` are one value |
| clock-24h-off | `services.sddm-astronaut.use24HourClock` and `services.hyprlock.use24HourClock` are `false` (12-hour greeter and lock clock, matching the 12-hour `en_IN` `LC_TIME`; both modules ignore `LC_TIME`) |
| glibc-locales-builds | the host's `i18n.glibcLocales` derivation (path taken from the same eval) really builds; a locale spelled the way glibc does not list it (`en_IN.UTF-8`) fails here with "unsupported locales detected" (the spelling trap itself is pinned in `nixos-locale`) |
| nix-pat-include | `nix.extraOptions` includes the PAT file under `/run/secrets` |
| pat-secret-declared | sops secret exists and resolves to that path |
| one-sddm-theme | exactly one of sddm-astronaut / sddm-pixie enabled |
| power-exclusive | at most one of auto-cpufreq/tlp enabled (conflict) |
| tailscale-trusted / reverse-path | `tailscale0` trusted, `checkReversePath == "loose"` |
| tailscale-operator | `--operator=<user>` in up/set flags |
| tailscale-authkey-sops | `services.tailscale.authKeyFile` is the path of the sops secret `tailscale_key`, owned by root (`owner = "root"`, or `owner = null` with `uid = 0`) with mode `0400` (login runs through upstream `tailscaled-autoconnect`) |
| hm-use-global-pkgs-enabled | `home-manager.useGlobalPkgs == true` |
| hm-use-user-packages | `home-manager.useUserPackages == true` |
| hm-plasma-manager-loaded | `home-manager.users.<user>.programs.plasma` is declared (plasma-manager reaches HM on NixOS; Darwin's HM lacks it, so the probe discriminates) |
| no-failing-assertions | `config.assertions` has no failing entry |
