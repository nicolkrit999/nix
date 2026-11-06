# test-recover-script

Unit tests for the lanzaboote-aware emergency script `Documentation/troubleshooting/recover.sh` (rebuild + reinstall the bootloader from a live USB). The script is only ever run when the machine does not boot, so its decisions (which bootloader, where the Secure Boot signing key lives, what a missing key or firmware entry does by default) must be proven in advance, without root, a network or a real disk.

## Run

Via the suite runner (from the repo root): `bash templates/tests/run-tests.sh --only nixos-recover-script` (name as shown by `--list`).

```bash
bash templates/tests/nixos/test-recover-script/check-nixos-recover-script.sh
```

Or from inside the directory:

```bash
bash check-nixos-recover-script.sh
```

## How it works

`recover.sh` is source-safe: `main`, `set -Eeuo pipefail`, `mktemp`, traps and the sudo re-exec only run when the file is executed directly, so `check-nixos-recover-script.sh` simply `source`s it and calls the helpers. It needs a bash with the `compgen` builtin, which the plain nix `bash` lacks: the script re-executes itself under the first of `$RECOVER_TEST_BASH`, `/run/current-system/sw/bin/bash`, `/usr/bin/bash`, `/bin/bash` that has it, else under a `bashInteractive` built from the flake's pinned nixpkgs.

Hermetic by construction:

- fixture "installed systems" (`nix/var/nix/profiles/system-3-link/etc/{fstab,sbctl/sbctl.conf}`, `boot/EFI/...`, `persist/var/lib/sbctl/keys/...`) are built inside one `mktemp -d` directory that is removed on exit; the key files hold placeholder text, nothing is a real key, fingerprint or token
- `MNT` always points into that directory; `EFIVARS_DIR` and `SYSFS_BLOCK` point at fixture directories
- a stub directory is put first on `PATH`: `mount`, `efibootmgr`, `findmnt`, `blkid`, `lsblk` return canned fixture data (fake device `fixdisk9p5`) and log writes; `sbctl`, `nix`, `nixos-enter` (except the one block that tests the output extraction), `nixos-rebuild`, `chroot`, `umount`, `cryptsetup`, `systemctl`, `sudo` and `unshare` are tripwires that log `UNEXPECTED ...` and exit 99, asserted empty at the end
- `read_gen_file` (which does a real `unshare` + `mount --bind`) is replaced by a plain file read on the fixture, the only seam; `info`/`ok`/`warn` are quieted and `warn` is logged
- no root, no network, no real disks

Every property has a control: the same tree with and without `db.key` / `db.pem`, a stub flipped to unsigned, grub vs lanzaboote trees, with vs without `/persist`, flake answer vs disk fallback. In addition the script mutates a copy of `recover.sh` six times (via `RECOVER_SCRIPT`, which points the whole check at another file) and re-runs itself against each copy: every mutant must make the checks fail, and a `sed` expression that stops matching fails as well. A genuine config bug in `recover.sh` shows up as a red check; diagnose before touching the test.

## Checks

### Sourcing
| Check | Expected |
|-------|----------|
| shell flags | unchanged by sourcing |
| temp dir | none created (private `TMPDIR`) |
| functions | `main`, `detect_bootloader_disk`, `lanza_preflight` defined |

### Bootloader detection on the disk
| Check | Expected |
|-------|----------|
| GRUB tree | `grub` |
| `sbctl.conf` + stubs | `lanzaboote` |
| stubs + systemd-boot as `EFI/BOOT/BOOTX64.EFI`, no `sbctl.conf` | `lanzaboote` |
| hybrid (lanzaboote files + GRUB leftovers) | `lanzaboote` |
| `sbctl.conf` next to a GRUB `BOOTX64.EFI` | `lanzaboote` |
| GRUB `BOOTX64.EFI` with stale stubs | `grub` |
| no evidence / no generation at all | `other` |
| ESP mounted at `/efi` | `lanzaboote` |
| control | grub and lanzaboote trees give different answers |

### Flake answer vs disk
| Check | Expected |
|-------|----------|
| parse `RECOVER-BL:lanzaboote:<pki>`, `RECOVER-BL:grub:` | bootloader and pkiBundle split correctly (empty pki allowed) |
| parse garbage / unknown bootloader | rejected |
| control | a valid line is accepted |
| flake lanzaboote vs disk grub; flake grub vs disk hybrid | flake wins, source "the flake" |
| flake eval fails (disk lanzaboote, disk grub); garbage output; no evidence | falls back to the disk, source "the disk" |
| control | flake answer and disk fallback differ on the same tree |
| `flake_eval_bootloader` with noisy `nixos-enter` output | last `RECOVER-BL` line extracted |
| `nixos-enter` fails | soft failure (return 1) |

### Key paths
| Check | Expected |
|-------|----------|
| flake `pkiBundle` (impermanence, custom non-impermanence) | `<pki>/keys`, `<pki>/GUID`, source "the flake" |
| `sbctl.conf` of the generation (impermanence and non-impermanence path) | its `keydir` / `guid`, source names the generation |
| default with `/persist` on the disk / without | `/persist/var/lib/sbctl` / `/var/lib/sbctl` |
| control | with and without `/persist` differ |

### Signing key presence
| Check | Expected |
|-------|----------|
| mutation: only `db.pem`, then `db.key` added | not ok, then ok |
| mutation: `db.key` without `db.pem` | not ok |
| keys present (impermanence path, non-impermanence path) | ok |
| keys missing | not ok |
| keys only under `/persist` for `/var/lib/sbctl` | `mount --bind <persist copy> <target>` attempted |
| control: keys already in place | no mount |
| PK/KEK missing, db present | still ok (warning only) |

### sbctl verify classification
| Check | Expected |
|-------|----------|
| all stubs, systemd-boot and fallback loader signed | 4 signed, 0 bad |
| unsigned kernels, GRUB, Windows | 5 expected, not bad |
| mutation: one stub flipped to unsigned | exactly 1 bad, 3 signed |
| unsigned stub, systemd-boot, fallback loader, ANSI-coloured stub | 4 bad |
| output without verdict lines | 0 / 0 / 0 |

### Live Secure Boot and ESP helpers
| Check | Expected |
|-------|----------|
| no `SecureBoot` efivar | `unknown` |
| value byte 1 / 0 | `1` / `0` |
| `esp_free_mb` | a number |
| `count_stubs`, `main_esp` | 1 stub; `/boot` and `/efi` found; none without an ESP |

### Firmware entry check
| Check | Expected |
|-------|----------|
| entry for the boot partition present | no warning, no write |
| no matching entry | warning and the exact `efibootmgr -c -d /dev/<disk> -p <n> -l '\EFI\BOOT\BOOTX64.EFI' -L 'NixOS lanzaboote'` with disk and partition derived from the fixture |
| `--yes` | creates nothing (default no) |
| user answers yes | `efibootmgr -c` runs with the derived arguments |
| partition number unreadable | nothing written, hand-made hint printed |

### Menu defaults and pre-flight
| Check | Expected |
|-------|----------|
| `choose_def` under `--yes` | picks the given default (1 and 3, which differ) |
| `choose_def` without a tty | picks the default |
| `lanza_preflight` with keys | returns 0 |
| `lanza_preflight` without keys under `--yes` | stops ("Everything is still mounted"), never returns, names the missing key |
| control | the two runs differ |
| no sbctl calls | the stub log has none |

### Hermeticity and mutations
| Check | Expected |
|-------|----------|
| tripwire stubs | no `UNEXPECTED` call logged |
| private temp dir | nothing left behind by sourcing |
| six mutants of `recover.sh` (db test on KEK, unsigned never recognised, GRUB leftovers undetected, disk beats flake, firmware entry default yes, missing-keys default continue) | each makes the checks fail, each `sed` really changes the file |
