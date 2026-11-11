# Secure Boot with lanzaboote (`services.lanzaboote`)

Reference for the `services.lanzaboote` module: what it does, its options, how keys are handled, firmware notes, migrating a host away from GRUB, recovery and caveats. Step-by-step enabling on a host: [Adding lanzaboote to a host](../../installation/lanzaboote.md).

## What it is and why

- Goal: own Secure Boot keys, so the LUKS TPM2 auto-unlock becomes tamper-resistant. Without Secure Boot, an attacker with disk access can swap the initrd (evil maid) and the TPM still unseals the disk key. With Secure Boot and a PCR 7 policy, only a boot chain signed with the local keys unseals it. On a host without LUKS it only protects the boot chain.
- Tooling: [lanzaboote](https://github.com/nix-community/lanzaboote) (flake input `lanzaboote`, pinned by tag, `nixpkgs.follows = "nixpkgs"`) replaces the bootloader install step. It writes signed UKI-style stubs plus a signed systemd-boot to the ESP. [sbctl](https://github.com/Foxboron/sbctl) creates the keys and enrolls them into the firmware, by hand.
- Choosing lanzaboote (`enable`) and telling the config that the firmware enforces Secure Boot (`secureBoot`) are two separate concerns. lanzaboote also works with Secure Boot off: the stub verifies kernel and initrd by embedded hash either way.
- A host without the module stays on GRUB. The shared `modules/nixos/toplevel/boot.nix` skips its whole GRUB block (including the stale-copy sync hook) when `services.lanzaboote.enable` is true.

## The module

File: `modules/nixos/services/lanzaboote.nix` (generic, off by default, enabled per host).

| Option | Default | Meaning |
|--------|---------|---------|
| `myconfig.services.lanzaboote.enable` | `false` | Use lanzaboote as the bootloader (replaces GRUB for this host) |
| `myconfig.services.lanzaboote.secureBoot` | `false` | Declares that the FIRMWARE enforces Secure Boot. It can never flip the BIOS setting; it only applies the matching hardening: requires `enable` and asserts that `boot.initrd.systemd.emergencyAccess` (`constants.emergencyAccess`) is off |
| `myconfig.services.lanzaboote.pkiBundle` | `"/persist/var/lib/sbctl"` | Directory holding `keys/` and `GUID` |
| `myconfig.services.lanzaboote.configurationLimit` | `10` | Number of generations kept on the ESP. Every generation also keeps its specialisations, so the boot menu grows with it |
| `myconfig.services.lanzaboote.consoleMode` | `"keep"` | `console-mode` in `loader.conf`: `"keep"` (firmware default), `"auto"`, `"max"` or a non-negative integer string |

Hosts that enable it:

| Host | LUKS | `secureBoot` | `configurationLimit` | `consoleMode` | Windows |
|------|------|--------------|----------------------|---------------|---------|
| `nixos-laptop` | yes (TPM2, PCR 7) | `true` | 5 | `"5"` | own ESP |
| `nixos-desktop` | no | `true` | 3 | `"keep"` | own ESP on another disk |

Both use the default `pkiBundle` and impermanence.

When enabled the module sets:

- `boot.loader.systemd-boot.enable = mkForce false` (lanzaboote requirement), GRUB off (asserted).
- `boot.lanzaboote = { enable = true; pkiBundle; configurationLimit; }` plus `boot.lanzaboote.settings."console-mode" = consoleMode` (at `mkDefault` priority; lanzaboote's `settings` option merges it over its own defaults, so `timeout`, `editor` and `default = "nixos-*"` stay as they are). `boot.loader.systemd-boot.consoleMode` is not used: that NixOS option is an enum that does not allow integers. Deliberately NOT set: `autoGenerateKeys`, `autoEnrollKeys`, `measuredBoot`, `allowUnsigned`.
- `pkgs.sbctl` and `reboot-to-windows` in `environment.systemPackages`.
- `/etc/sbctl/sbctl.conf` with the same `keydir`/`guid` pair lanzaboote itself writes for auto key generation:

  ```yaml
  guid: <pkiBundle>/GUID
  keydir: <pkiBundle>/keys
  ```

  Without this file a manual `sbctl create-keys` would use sbctl's default `/var/lib/sbctl`, which is on the tmpfs root of an impermanence host and vanishes on reboot.
- A tmpfiles rule `d <pkiBundle> 0700 root root -`: sbctl itself creates the directory with mode 0755 (the private key files are 0400 root), so it is pre-created root-only.

Assertions: GRUB must be disabled; with `services.impermanence` enabled, `pkiBundle` must start with `/persist/`; `consoleMode` must be `keep`, `auto`, `max` or digits only; `secureBoot = true` requires `enable = true` and `boot.initrd.systemd.emergencyAccess = false` (an initrd root shell defeats Secure Boot). `secureBoot` does nothing else: the TPM re-seal (`tpm-reenroll`, PCR 7) is a manual step.

### The boot menu looks small

`consoleMode` selects the UEFI text mode of the systemd-boot menu. The numbers are firmware specific. To find one: in the systemd-boot menu press `r` to cycle through the available modes (the menu redraws in each); set the chosen number as `consoleMode = "<n>"`. Alternatively edit `console-mode` in `/boot/loader/loader.conf` (the file is rewritten by the next bootloader install, so persist the value via the option). `"max"` picks the largest mode, `"keep"` leaves the firmware default.

### Why the keys are used directly from `/persist`

No bind mount and no `environment.persistence` entry on purpose. `/persist` is a `neededForBoot` btrfs subvolume, so the path is real in the initrd, in the running system, and in a live-ISO chroot where only `/persist` is mounted (bind mounts from impermanence do not exist there). That chroot is exactly where `nixos-rebuild boot --install-bootloader` must still find the signing key when recovering.

## Keys

- Create: `sudo sbctl create-keys` (after the module is active, so `/etc/sbctl/sbctl.conf` points at `pkiBundle`). Check: `sudo ls -ld <pkiBundle>` shows `drwx------`.
- Back up: one encrypted copy in the password manager (password manager), made right after creation: `sudo tar -C <parent of pkiBundle> -czf /dev/shm/sbctl-keys.tar.gz sbctl`, `sudo chown $USER /dev/shm/sbctl-keys.tar.gz`, upload it, `rm` it. Never put the key directory into borg, the repo or any remote copy: exclude it from the host's borg job (derive the exclusion from the `pkiBundle` option).
- The keys are only needed to sign new boot files. Nothing at activation or boot reads them; only the install hook does.

## What the install hook does (facts from the lanzaboote source)

- Runs from `switch-to-configuration` on `switch` and `boot`, NOT on `test`. `nixos-rebuild test` therefore never touches the bootloader; it does activate `/etc/sbctl/sbctl.conf` and creates the key directory.
- If the keys are missing (and `allowUnsigned` is false) it fails at the very first key read, before any file is written to the ESP. Safe, but the rebuild fails.
- Writes: `EFI/nixos/kernel-*.efi` and `initrd-*.efi` (unsigned, content-addressed copies), `EFI/Linux/nixos-generation-<N>[-specialisation-<name>]-<hash>.efi` (signed stubs), `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` (signed systemd-boot), `loader/loader.conf`. It never writes EFI variables and never calls efibootmgr.
- `EFI/BOOT/BOOTX64.EFI` (GRUB, on a migrated host) is overwritten without a backup. It never touches `EFI/NixOS-boot` (the GRUB copy a firmware entry may point to), `/boot/grub`, `/boot/kernels`, `EFI/Microsoft`, `EFI/Dell`.
- Garbage collection on the ESP only removes unreferenced files in `EFI/nixos/` and `nixos-*` files in `EFI/Linux/`.
- About 65-165 MiB per distinct kernel + initrd set on the ESP.
- `sudo sbctl verify`: every `EFI/Linux/*.efi`, `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` must be signed; `EFI/nixos/kernel-*.efi` stays unsigned by design (the signed stub checks it by hash).

Read-only status helpers: `bootctl status`, `efibootmgr -v`, `sudo sbctl status`, `df -h /boot; du -sh /boot/*`, `cat /sys/kernel/security/lockdown`.

## Enrolling keys and turning Secure Boot on

The commands are in the [installation guide](../../installation/lanzaboote.md) (phases 2 and 3). The key command is:

```
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

`--microsoft` adds the Microsoft CAs (the Windows boot manager and many option ROMs are signed by them), `--firmware-builtin` keeps the firmware's own default db entries so firmware-signed components keep loading. Add `--ignore-immutable` only if an immutable-efivar error appears. The firmware must be in Setup Mode first (`sudo sbctl status` shows `Setup Mode: Enabled`), which is vendor specific, see the next section.

After Secure Boot is on, `bootctl status | grep -i "secure boot"` reports `enabled (user)` (or `enabled (deployed)` on firmware that exposes Deployed Mode).

## Firmware notes (reference)

Menu names differ per vendor and per BIOS version.

### Dell (XPS 16)

- Setup Mode: BIOS (admin password) > Secure Boot > Expert Key Management > Enable Custom Mode > delete the PK (or Delete All Keys) > Secure Boot Mode = Audit Mode. Then boot NixOS and enroll.
- Turn it on: Secure Boot ON, Deployed Mode. Re-check `sudo sbctl list-enrolled-keys` afterwards (toggling Custom Mode may restore factory keys on some firmware).
- Back to factory keys: Expert Key Management > Custom Mode > Reset All Keys > Deployed Mode.
- One-time boot menu F12, BIOS setup F2.

### MSI MEG X670E ACE

- Standard Secure Boot mode restores the factory keys. To enter Setup Mode: Secure Boot Mode = Custom, "Provision Factory Default keys" = Disabled, then "Delete all Secure Boot variables". Afterwards `sbctl status` shows Setup Mode enabled; enroll with the command above.
- The dbx is empty after deleting the keys. Optionally restore Microsoft's revocation list with fwupd.
- sbctl finding FQ0001: 600-series/X670E boards skip Secure Boot verification by default (Image Execution Policy = Always Execute), so the BIOS shows Secure Boot as enabled while nothing is enforced and an image signed with a key that was never enrolled still boots. After enrolling the keys set Secure Boot Preset = Maximum Security, or set Image Execution Policy (Option ROM, Removable Media, Fixed Media) to Deny Execute. Never use Always Deny: it also refuses the signed images the firmware needs and can require a CMOS clear.
- Enter the BIOS without F-keys: `systemctl reboot --firmware-setup`.

## BootOrder and firmware entries

lanzaboote writes no EFI variables. The firmware starts either an entry created by hand or the removable fallback `\EFI\BOOT\BOOTX64.EFI` (systemd-boot after the first install). `\EFI\systemd\systemd-bootx64.efi` is the same loader at its canonical path.

- Check: `efibootmgr -v`. The lanzaboote loader must be first in BootOrder; reorder with `sudo efibootmgr -o <entries>`.
- Create a dedicated entry (also after an NVRAM reset): `sudo efibootmgr -c -d /dev/<disk> -p <esp-partition-number> -l '\EFI\systemd\systemd-bootx64.efi' -L "NixOS lanzaboote"`.
- Device names can change with several disks: identify disks by by-id, serial or PARTUUID, never by `nvme0n1`/`sda`.

## Windows on another ESP: `reboot-to-windows`

systemd-boot only lists Windows if its boot manager is on the same ESP. A Windows on another disk or another ESP cannot be listed. `reboot-to-windows` finds the firmware entry at run time (`efibootmgr -v`, an entry named "Windows Boot Manager" or whose path contains `\EFI\Microsoft\Boot\bootmgfw.efi`, case-insensitive; the number is never hardcoded), sets `efibootmgr --bootnext <XXXX>` and runs `systemctl reboot`. It is not root: it re-executes itself through sudo. Several matches: the first is used and all are printed. None: prints "no Windows boot entry found" to stderr, exits 1 and does not reboot. Alternative: the firmware boot menu. Test hooks (environment): `REBOOT_TO_WINDOWS_EFIBOOTMGR`, `REBOOT_TO_WINDOWS_SYSTEMCTL`, `REBOOT_TO_WINDOWS_SUDO` replace the three commands it calls.

If Windows uses BitLocker or device encryption, have the recovery key ready before changing Secure Boot keys (the change alters PCR 7 and triggers a recovery prompt).

## Migrating from GRUB: cleanup runbook

**Why it exists.** lanzaboote only deletes its own files (`EFI/nixos/` and `nixos-*` entries in `EFI/Linux/`). GRUB's files stay on the ESP after the switch. With Secure Boot ON the firmware refuses the unsigned GRUB, so they are dead weight: space on the ESP, red crosses in `sbctl verify`, and possibly a GC root that pins the old GRUB generation in `/nix/store`. Nothing cleans them automatically, so this is a manual, one-time step. It changes no Nix config.

**ESP space warning.** GRUB's `/boot/kernels` and lanzaboote's `EFI/nixos` both hold kernels and initrds, so right after the switch the ESP carries both sets. A 1 GiB ESP fills up quickly: remove the GRUB leftovers before further rebuilds, or lower `boot.loader.grub.configurationLimit` and rebuild before enabling lanzaboote. A full ESP makes the install hook fail mid-write; see Recovery.

**What the leftovers are**

| Item | What it is | Why it is still there |
|---|---|---|
| firmware entry `Boot<entry-number> NixOS-boot` | UEFI boot entry pointing at `\EFI\NixOS-boot\grubx64.efi` | created by the old GRUB install; the lanzaboote install writes no EFI variables, so it never removes it |
| `/boot/EFI/NixOS-boot/` (`grubx64.efi`, `grubx64.efi.old`) | the GRUB program the entry starts, and its previous copy | old GRUB install |
| `/boot/grub/` | GRUB config, `grubenv`, fonts, locales, `x86_64-efi` modules (`core.efi`, `grub.efi`) | old GRUB install |
| `/boot/kernels/` | kernels and initrds that GRUB copied to the ESP | old GRUB install |
| GC root `/nix/var/nix/gcroots/grub-fallback-<profile-gen>` | symlink that pins the frozen GRUB generation's closure | only if created by hand to keep it bootable; `nh clean` can never free it while it exists |

Everything else on the ESP stays: `EFI/BOOT/` (signed systemd-boot), `EFI/systemd/`, `EFI/Linux/` (signed stubs), `EFI/nixos/`, vendor directories such as `EFI/Dell/`, `EFI/Microsoft/`, and `loader/`.

**Prerequisites (all must be true; if one is not, stop)**
1. Several days of normal use under lanzaboote with no boot problem: cold boots, suspend/resume, each specialisation in use, the other OS, and at least one new generation installed with `nh os boot .`.
2. `sudo sbctl verify`: every `EFI/Linux/*.efi`, `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` is signed (the only expected crosses are the GRUB leftovers and `EFI/nixos/kernel-*.efi`).
3. If Secure Boot is on: `bootctl status | grep -i "secure boot"` says enabled, and `efibootmgr` shows `BootCurrent` and the first `BootOrder` entry on the lanzaboote loader, not on the GRUB entry that is about to disappear.
4. A fresh archive of the ESP exists, stored off the disk: `sudo tar -C /boot -cpf ~/esp-before-cleanup.tar .`.

**Commands (sudo), in this order**

| # | Command | What it does |
|---|---------|--------------|
| 1 | `efibootmgr \| grep -i nixos-boot` | shows the entry number of the GRUB entry; confirm it before deleting by number |
| 2 | `sudo efibootmgr -b <entry-number> -B` | deletes the firmware entry and removes it from `BootOrder` |
| 3 | `sudo rm -r /boot/EFI/NixOS-boot` | deletes the GRUB program and its previous copy |
| 4 | `sudo rm -r /boot/grub` | deletes GRUB's config, `grubenv`, fonts, locales and modules |
| 5 | `sudo rm -r /boot/kernels` | deletes the kernels/initrds GRUB copied |
| 6 | `sudo rm /nix/var/nix/gcroots/grub-fallback-<profile-gen>` | only if the root exists: removes the symlink (not the store paths), so the next `nh clean` can free the old generation |

Do not touch `/boot/EFI/nixos`, `/boot/EFI/Linux`, `/boot/EFI/BOOT`, `/boot/EFI/systemd`, vendor directories or `/boot/loader`.

**Verify**
- `sudo sbctl verify`: exactly one kind of red cross is left, `EFI/nixos/kernel-*.efi`.
- `efibootmgr`: no `NixOS-boot` entry; the lanzaboote loader is first in BootOrder.
- `df -h /boot`: space freed.
- Reboot: NixOS boots from the systemd-boot menu, a LUKS host unlocks via the TPM, the other OS still boots.
- `nh os boot .` still installs a generation without errors.

**Rollback.** GRUB only boots while Secure Boot is OFF (it is unsigned). Restore from the archive: `sudo tar -C /boot -xpf ~/esp-before-cleanup.tar ./EFI/NixOS-boot ./grub ./kernels`, recreate the firmware entry `sudo efibootmgr -c -d /dev/<disk> -p <esp-partition-number> -L NixOS-boot -l '\EFI\NixOS-boot\grubx64.efi'`. What is lost by cleaning up: the "turn Secure Boot off, pick the old GRUB entry" fallback, which is rarely needed because the lanzaboote entries also boot with Secure Boot off. If the systemd-boot files themselves are broken, use the live-ISO path below.

## Recovery

- Boot fails with Secure Boot ON: enter the BIOS (admin password), disable Secure Boot, boot an older generation from the systemd-boot menu. The older entries are signed too.
- Power loss during install / hash verification failure: boot an older generation, check `sbctl verify /boot/EFI/Linux/nixos-generation-*.efi`, delete corrupt files, `nixos-rebuild boot`. If nothing boots: live NixOS ISO with Secure Boot OFF, mount the ESP (`fsck.fat` if needed), `rm -fr /mnt/boot/EFI/Linux/nixos-generation-*.efi /mnt/boot/EFI/nixos`, `nixos-enter`, `nixos-rebuild boot --install-bootloader`. For the tmpfs root, mount the btrfs subvolumes as in [emergency-recovery.md](../../troubleshooting/emergency-recovery.md) section 1B; the key directory must be reachable at `pkiBundle`.
- [`recover.sh`](../../troubleshooting/recover.sh) automates exactly this for lanzaboote hosts as well as GRUB hosts: Secure Boot OFF in the BIOS first, then it unlocks and mounts, asks the flake which bootloader it builds, checks the signing key under `pkiBundle` (it never creates keys on its own; a missing key stops with the options to restore the archive, continue anyway, or create new keys after a typed confirmation), runs `nixos-rebuild boot --install-bootloader` in the chroot, then `sbctl verify` and a firmware-entry check that prints the exact `efibootmgr -c` command if the NVRAM lost its entry. Walkthrough: [troubleshooting/README.md](../../troubleshooting/README.md).
- After a repair from the live ISO: re-enable Secure Boot in the BIOS; a LUKS + TPM host unlocks by itself again only if PCR 7 is unchanged, otherwise re-seal: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 <luks-device>`.
- Restore the ESP from a backup archive: live ISO, `sudo mount <esp-device> /mnt/esp && sudo tar -C /mnt/esp -xpf <esp-archive>` (check first what you overwrite).
- Back to factory keys: see the firmware notes above for the vendor's menu.
- Lost signing key: the keys are only needed to sign new boot files. Enter the BIOS, disable Secure Boot, `sbctl create-keys` again, repeat the key enrollment and Secure Boot steps of the installation guide (the enrolled db then has to be replaced).

## Caveats

- lanzaboote describes itself as having "sharp edges"; the recovery path above matters.
- The stub measures kernel/initrd/cmdline into PCR 11/12/13; measured boot (pcrlock) is intentionally off (it limits the ESP to few generations).
- Recovery or installer ISOs need Secure Boot OFF once it is on.
- The flake input builds the Rust UEFI stub locally (no binary cache is declared by lanzaboote), which costs build time on a cold cache.
