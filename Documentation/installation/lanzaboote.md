# Adding lanzaboote (signed boot) to a host

Use this after (or while) installing a host with [disko.md](./disko.md) or [manual.md](./manual.md). Lanzaboote is its own choice: it is independent of disk encryption (LUKS) and of firmware Secure Boot. The module is `services.lanzaboote` (`modules/nixos/services/lanzaboote.nix`); options, key handling, firmware notes, the GRUB cleanup runbook, recovery and caveats are in [../usage/secure-boot/lanzaboote.md](../usage/secure-boot/lanzaboote.md). This page covers the procedure for a host, **without LUKS** versus **with LUKS**.

## Pick your variant

| | A: without LUKS | B: with LUKS (+ TPM auto-unlock) |
|---|---|---|
| Installed with | disko Option A / manual Option A | disko Option B / manual Option B |
| Secure Boot protects | the boot chain (bootloader, kernel, initrd). `/nix` and `/persist` are plain on disk, so someone with physical access can still alter them offline | the boot chain **and** the disk contents are unreadable offline |
| TPM step | none (there is no passphrase to replace) | re-seal the TPM to **PCR 7 only**, after Secure Boot is on |
| Extra backup | none | LUKS header backup |
| Passphrase prompt | never | once after the key changes, then gone after the re-seal |

Both variants share the same phases; the differences are marked below.

## Layout check: where do the signing keys live?

The default `pkiBundle` is `/persist/var/lib/sbctl`. That is right for an **impermanence** layout (tmpfs root + `@persist`, e.g. disko Option B or the manual layouts that create `@persist`); an assertion fails the build if impermanence is on and the path is not under `/persist/`.

The disko **Option A** template (`disko-config-btrfs.nix`) is a plain btrfs root with **no** `/persist`. For that layout set the bundle to a path on the root filesystem:

```nix
services.lanzaboote.pkiBundle = "/var/lib/sbctl";
```

(Keep the directory out of any backup either way, see "Backups and cleanup" below.)

## Why two steps (install first, enable lanzaboote second)

The module deliberately does not generate or enroll keys (`autoGenerateKeys`/`autoEnrollKeys` stay off), and lanzaboote signs at install time, so the keys must exist before its bootloader hook runs. The path is therefore:

1. Install the host normally. It boots with GRUB, which is the shared default (`modules/nixos/toplevel/boot.nix`).
2. Enable lanzaboote on the running system (Phase 1 below). GRUB stays as the fallback until Secure Boot is verified.

## Before you start (both variants)

- Pull the repo on the host, make sure the host appears in `hosts/` with its `hardware-configuration.nix`, and `git add` any new file.
- ESP size: each distinct kernel+initrd set is roughly 65-165 MiB and every generation adds one signed stub per specialisation. The guides ask for a 1-4 GiB ESP. On a 1 GiB ESP set a small `configurationLimit` (3-5), and note that GRUB's `/boot/kernels` and lanzaboote's `EFI/nixos` both hold initrds: lower `boot.loader.grub.configurationLimit` and rebuild before Phase 1, then remove the GRUB leftovers promptly (see the cleanup runbook in the usage doc).
- Firmware: note the vendor and the exact menu names for Secure Boot key management (they differ per vendor, see the firmware notes in the usage doc). Know the BIOS/admin password and store it in your password manager.
- Dual boot with Windows on **another** disk or another ESP: systemd-boot only detects Windows on its own ESP, so after the switch Windows is reached through `reboot-to-windows` (installed by the module) or the firmware boot menu. If Windows uses BitLocker/device encryption, make sure you have the recovery key before changing Secure Boot keys (the change alters PCR 7 and triggers a recovery prompt). Ignore both points on a single-OS host.
- Variant B only: back up the LUKS header **off the disk** (`sudo cryptsetup luksHeaderBackup <luks-device> --header-backup-file <file>`; the file is root-owned 0400, so copy it with `sudo cat file | ssh host 'cat > dest'` and verify size and sha256; a plain user copy of the root-only file is empty).
- Back up the ESP: `sudo tar -C /boot -cpf ~/esp-before-lanzaboote.tar .` and keep it off the disk.

## Phase 1: enable lanzaboote with Secure Boot still OFF (both variants)

1. In the host file (inside the `myconfig.services` block, like `hosts/nixos-laptop/default.nix`):
   ```nix
   lanzaboote = {
     enable = true;
     secureBoot = false;   # flips to true only after Phase 3
     configurationLimit = 5;
     consoleMode = "keep"; # the menu may look small; see usage/secure-boot/lanzaboote.md for the r-key trick
   };
   ```
   Add the key directory to the host's borg exclusion if the host has a borg module (the existing host files derive it from `myconfig.services.lanzaboote.pkiBundle`).
2. `git add` and `nh os test .` (needs sudo). If fwupd is enabled, `fwupd-efi.service` fails once because the key does not exist yet: expected.
3. `sudo sbctl create-keys`, then `sudo systemctl restart fwupd-efi.service` if it failed.
4. Back up the keys to your password manager, never to borg or the repo: `sudo tar -C <parent of pkiBundle> -czf /dev/shm/sbctl-keys.tar.gz sbctl`, `sudo chown $USER /dev/shm/sbctl-keys.tar.gz`, upload it, then `rm` it. Never paste the archive anywhere.
5. Optional: pin the GRUB generation so `nh clean` cannot delete it while GRUB is still the fallback: `sudo ln -s "$(readlink -f /nix/var/nix/profiles/system-<profile-gen>-link)" /nix/var/nix/gcroots/grub-fallback-<profile-gen>` for the generation GRUB boots. Remove it in the cleanup.
6. `nh os boot .` (not `switch`), then `sudo sbctl verify`: every `EFI/Linux/*.efi`, `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` must be signed; the old GRUB files and `EFI/nixos/kernel-*.efi` stay red by design.
7. Reboot, open the firmware boot menu and start the NixOS ESP's `\EFI\BOOT\BOOTX64.EFI` entry (systemd-boot). Test every specialisation in use and suspend/resume.
8. Put it first with GRUB second: `sudo efibootmgr -o <new>,<grub>,<others>` (check `efibootmgr -v`; to create a dedicated entry see "BootOrder and firmware entries" in the usage doc). Variant B: the TPM unlock should still work at this point because Secure Boot has not changed yet.
9. Gate before moving on: several boots through the new entry, one rebuild plus reboot cycle with a new generation, TPM unlock still works (variant B), `bootctl status` sane, `sudo sbctl verify` clean.

## Phase 2: enroll your keys (Secure Boot still OFF)

1. BIOS: delete all Secure Boot keys / Platform Key so the firmware enters Setup Mode; if offered, choose Audit Mode. Leave Secure Boot itself off. The menu path is vendor specific (usage doc, firmware notes). Variant B: the next boot asks for the LUKS passphrase once, since PCR 7 changed. Do **not** re-seal yet.
2. `sudo sbctl status` must say `Setup Mode: Enabled` (sbctl draws a red cross there; that is correct).
3. `sudo sbctl enroll-keys --microsoft --firmware-builtin` (add `--ignore-immutable` only if sbctl asks). `sbctl status` must now say Setup Mode Disabled; `sudo sbctl verify` is still clean.

## Phase 3: turn Secure Boot on

1. If a stale unsigned GRUB firmware entry exists, remove or reorder it first (`sudo efibootmgr -b <entry-number> -B`, or `-o` so a signed entry comes first). Keep a copy of `efibootmgr -v` before.
2. BIOS: Secure Boot ON (Deployed/User Mode). Boot NixOS; `bootctl status | grep -i "secure boot"` must say `enabled (user)` or `enabled (deployed)`. Re-check `sudo sbctl list-enrolled-keys` (some firmware restores factory keys when toggling Custom Mode).
3. Boot the other OS (Windows etc.) from the firmware menu or `reboot-to-windows` to confirm it still starts. If anything refuses to boot, switch Secure Boot off in the BIOS to get back.
4. Variant B only: re-seal the TPM **to PCR 7 only** (the old 0+7 or 0+2+7 values change on firmware updates and key changes): `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 <luks-device>`. Verify with `sudo cryptsetup token export --token-id <id> <luks-device>`; it must show `"tpm2-pcrs":[7]` (`luksDump` does not show PCRs). The `tpm-reenroll` shell helper does the same for every crypt device. Reboot: no passphrase prompt. Variant A has no TPM step.
5. In the host: `constants.emergencyAccess = false` (an initrd root shell defeats Secure Boot; the module asserts it) and `services.lanzaboote.secureBoot = true`, then rebuild.

The disko/manual guides bind the TPM with `--tpm2-pcrs=0+7` for a **GRUB** host. On a lanzaboote host with Secure Boot, use PCR 7 only, and only after Phase 3.

## Backups and cleanup

- The signing keys are a root-only secret: exclude them from borg and the repo; keep one encrypted copy in a password manager.
- After a stable period remove the old GRUB leftovers: the cleanup runbook in the usage doc ("Migrating from GRUB"). Nothing cleans the GRUB files automatically.

## If something goes wrong

Secure Boot off in the BIOS gets you back; the lanzaboote entries also boot with Secure Boot off. For a broken ESP, the live-ISO procedure and the key-loss case are in the Recovery section of [../usage/secure-boot/lanzaboote.md](../usage/secure-boot/lanzaboote.md).
