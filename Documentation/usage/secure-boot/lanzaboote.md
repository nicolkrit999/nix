# Secure Boot with lanzaboote (`services.lanzaboote`)

Status: Phase 1 only (the module exists and is enabled on `nixos-laptop`, live-verified; `secureBoot = false`, Secure Boot itself stays OFF in the firmware, nothing is enrolled yet). The sections "Phase 2" and "Phase 3" describe the planned next steps; nothing in them has been run yet.

## What it is and why

- Goal: own Secure Boot keys, so the LUKS TPM2 auto-unlock becomes tamper-resistant. Without Secure Boot, an attacker with disk access can swap the initrd (evil maid) and the TPM still unseals the disk key. With Secure Boot and a PCR 7 policy, only a boot chain signed with the local keys unseals it.
- Tooling: [lanzaboote](https://github.com/nix-community/lanzaboote) (flake input `lanzaboote`, tag `v1.2.0`, `nixpkgs.follows = "nixpkgs"`) replaces the bootloader install step. It writes signed UKI-style stubs plus a signed systemd-boot to the ESP. [sbctl](https://github.com/Foxboron/sbctl) creates the keys and enrolls them into the firmware, by hand.
- Only `nixos-laptop` uses it. `nixos-desktop` stays on GRUB; the shared `modules/nixos/toplevel/boot.nix` skips its whole GRUB block (including the stale-copy sync hook) when `services.lanzaboote.enable` is true, and is otherwise unchanged.

## The module

File: `modules/nixos/services/lanzaboote.nix` (generic, off by default, enabled per host). The module is named after the bootloader, not after Secure Boot: choosing lanzaboote (`enable`) and telling the config that the firmware enforces Secure Boot (`secureBoot`) are two separate concerns.

| Option | Default | Meaning |
|--------|---------|---------|
| `myconfig.services.lanzaboote.enable` | `false` | Use lanzaboote as the bootloader (replaces GRUB for this host) |
| `myconfig.services.lanzaboote.secureBoot` | `false` | Declares that the FIRMWARE enforces Secure Boot. It can never flip the BIOS setting; it only applies the matching hardening: requires `enable` and asserts that `boot.initrd.systemd.emergencyAccess` is off |
| `myconfig.services.lanzaboote.pkiBundle` | `"/persist/var/lib/sbctl"` | Directory holding `keys/` and `GUID` |
| `myconfig.services.lanzaboote.configurationLimit` | `10` | Number of generations kept on the ESP (the laptop uses 5: 5 generations x (base + 5 specialisations) menu entries) |
| `myconfig.services.lanzaboote.consoleMode` | `"keep"` | `console-mode` in `loader.conf`: `"keep"` (firmware default), `"auto"`, `"max"` or a non-negative integer string. The laptop uses `"5"` |

When enabled it sets:

- `boot.loader.systemd-boot.enable = mkForce false` (lanzaboote requirement), GRUB off (asserted).
- `boot.lanzaboote = { enable = true; pkiBundle; configurationLimit; }` plus `boot.lanzaboote.settings."console-mode" = consoleMode` (at `mkDefault` priority; lanzaboote's `settings` option merges it over its own defaults, so `timeout`, `editor` and `default = "nixos-*"` stay as they are). `boot.loader.systemd-boot.consoleMode` is not used: that NixOS option is an enum that does not allow integers. Deliberately NOT set: `autoGenerateKeys`, `autoEnrollKeys`, `measuredBoot`, `allowUnsigned`.
- `pkgs.sbctl` in `environment.systemPackages`.
- `/etc/sbctl/sbctl.conf` with the same `keydir`/`guid` pair lanzaboote itself writes for auto key generation (YAML, two keys; order is not significant):

```yaml
guid: /persist/var/lib/sbctl/GUID
keydir: /persist/var/lib/sbctl/keys
```

  Without this file a manual `sbctl create-keys` would use sbctl's default `/var/lib/sbctl`, which is on the tmpfs root and vanishes on reboot. sbctl reads `/etc/sbctl/sbctl.conf` automatically; only `keydir` and `guid` are used to find the keys.
- A tmpfiles rule `d /persist/var/lib/sbctl 0700 root root -`: sbctl itself creates the directory with mode 0755 (the private key files are 0400 root), so the directory is pre-created root-only.

Assertions: GRUB must be disabled; with `services.impermanence` enabled, `pkiBundle` must start with `/persist/`; `consoleMode` must be `keep`, `auto`, `max` or digits only; `secureBoot = true` requires `enable = true` and `boot.initrd.systemd.emergencyAccess = false` (an initrd root shell defeats Secure Boot). `secureBoot` does nothing else: the `tpm-reenroll` PCR change and the removal of the stale GRUB firmware entry stay manual steps of Phase 3.

### The boot menu looks small?

`consoleMode` selects the UEFI text mode of the systemd-boot menu. The numbers are firmware specific (mode 5 is the right one on the XPS 16 panel, another machine differs). To find one: in the systemd-boot menu press `r` to cycle through the available modes (the menu redraws in each); the chosen number can then be set as `consoleMode = "<n>"`. Alternatively edit `console-mode` in `/boot/loader/loader.conf` (the file is rewritten by the next bootloader install, so persist the value via the option). `"max"` picks the largest mode, `"keep"` leaves the firmware default.

### Why the keys are used directly from `/persist`

No bind mount and no `environment.persistence` entry on purpose. `/persist` is a `neededForBoot` btrfs subvolume, so the path is real in the initrd, in the running system, and in a live-ISO chroot where only `/persist` is mounted (bind mounts from impermanence do not exist there). That chroot is exactly where `nixos-rebuild boot --install-bootloader` must still find the signing key when recovering.

### Backup of the signing key

The key directory is excluded from the borg backup of `nixos-laptop` (`users/krit/nixos/services/nas/borg-backup/borg-backup-laptop.nix`, derived from the `pkiBundle` option; the desktop job is untouched). The private key is a root-only secret and must not end up in the remote repo. Keep one encrypted offline copy instead (password manager attachment of an archive of the directory), created right after `sbctl create-keys`.

## What the install hook does (facts from the lanzaboote source, v1.2.0)

- Runs from `switch-to-configuration` on `switch` and `boot`, NOT on `test`. `nixos-rebuild test` therefore never touches the bootloader; it does activate `/etc/sbctl/sbctl.conf` and (via `systemd-tmpfiles-resetup`) creates the key directory.
- Nothing at activation or boot needs the keys. Only the install hook reads them (plus lanzaboote's fwupd signing service, which is inactive because fwupd is not enabled in this repo). If the keys are missing (and `allowUnsigned` is false) it fails at the very first key read, before any file is written to the ESP. Safe, but the `nixos-rebuild boot` run then fails.
- Writes: `EFI/nixos/kernel-*.efi` and `initrd-*.efi` (unsigned, content-addressed copies), `EFI/Linux/nixos-generation-<N>[-specialisation-<name>]-<hash>.efi` (signed stubs), `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` (signed systemd-boot), `loader/loader.conf`. It never writes EFI variables and never calls efibootmgr.
- `EFI/BOOT/BOOTX64.EFI` (which is GRUB today) is overwritten without a backup. It never touches `EFI/NixOS-boot` (the stale GRUB copy the firmware entry points to), `/boot/grub`, `/boot/kernels`, `EFI/Microsoft`, `EFI/Dell`.
- Garbage collection on the ESP only removes unreferenced files in `EFI/nixos/` and `nixos-*` files in `EFI/Linux/`.
- About 163 MiB per distinct kernel + initrd set on the ESP; the 4 GiB ESP holds `configurationLimit = 10` with room to spare (the laptop uses 5).
- Windows has its own ESP on this machine. lanzaboote (systemd-boot) cannot chainload it: use the firmware boot menu (F12) or `sudo efibootmgr --bootnext <id of "Windows Boot Manager">` then reboot (parked workflow, no helper yet).

## Procedure

Everything needing root is marked (sudo). Device names are those of `nixos-laptop`: NixOS ESP `/dev/nvme0n1p5`, LUKS `/dev/nvme0n1p6`, Windows ESP `/dev/nvme0n1p1`.

### Phase 0: backups (do before anything else)

- (sudo) `sudo tar -C /boot -cpf ~/momentary/esp-nixos.tar .`
- (sudo) `sudo cryptsetup luksHeaderBackup /dev/nvme0n1p6 --header-backup-file ~/momentary/luks-header.img` (keep a copy OFF the disk; useless if the header breaks and the disk is unreadable)
- (sudo) `sudo dd if=/dev/nvme0n1p1 of=$HOME/momentary/esp-windows.img bs=1M status=progress` (`$HOME`, dd does not expand `~`)
- (sudo) LUKS passphrase test, no change: `sudo cryptsetup open --test-passphrase /dev/nvme0n1p6`
- BIOS admin password, LUKS passphrase and borg/sops secrets are in the password manager.

### Phase 1: lanzaboote installed, Secure Boot still OFF

1. Stage the change (`git add` new files) and let the checks pass, including a real `nix build` of the laptop toplevel.
2. `nixos-rebuild test --flake .#nixos-laptop` (activates `/etc/sbctl/sbctl.conf` and creates the 0700 key directory; does not touch the bootloader).
3. (sudo) `sudo sbctl create-keys`. Keys land in `/persist/var/lib/sbctl` (root-only). Check: `sudo ls -ld /persist/var/lib/sbctl` shows `drwx------`. Archive that directory encrypted into the password manager, NOT into borg.
4. Pin the frozen GRUB generation so `nh clean` cannot delete it (the GRUB menu entries still point at its store paths). Use the number of the generation GRUB currently boots (517 at the time of writing):
   `sudo nix-store --add-root /nix/var/nix/gcroots/grub-fallback-517 -r /nix/var/nix/profiles/system-517-link`
   Verify with `sudo nix-store --gc --print-roots | grep grub-fallback`. The root keeps the generation's store paths alive even after `nh clean` removes the profile link itself.
5. `nixos-rebuild boot --flake .#nixos-laptop` (NOT `switch`; installs lanzaboote). Then (sudo) `sudo sbctl verify`: the stubs, `BOOTX64.EFI` and `systemd-bootx64.efi` must be signed; `kernel-*` / `initrd-*` files in `EFI/nixos/` are expected unsigned.
6. Reboot and press F12. Pick the entry that is the fallback loader on the NixOS ESP (`\EFI\BOOT\BOOTX64.EFI`, now systemd-boot; "UEFI Lexar ... 2", Boot0004 at the time of writing). The normal power-on still boots the old GRUB (Boot0000).
   Optional dedicated firmware entry: `sudo efibootmgr -c -d /dev/nvme0n1 -p 5 -l '\EFI\systemd\systemd-bootx64.efi' -L "NixOS lanzaboote"`.
7. Gate before moving on (a checklist, no fixed duration): several F12 boots; one boot of every specialisation in use (school, guest, home); suspend/resume; one rebuild plus reboot cycle with a new generation; TPM unlock still works; `bootctl status` sane; `sudo sbctl verify` clean.

Read-only status helpers: `bootctl status`, `efibootmgr -v`, `sudo sbctl status`, `df -h /boot; du -sh /boot/*`, `cat /sys/kernel/security/lockdown`.

### Phase 2: Dell BIOS Setup Mode and key enrollment (planned)

1. BIOS (admin password): Secure Boot > Expert Key Management > Enable Custom Mode > delete the PK (or Delete All Keys) > Secure Boot Mode = Audit.
2. Boot NixOS via F12, then (sudo) `sudo sbctl status` must show Setup Mode: Enabled.
3. (sudo) `sudo sbctl enroll-keys --microsoft --firmware-builtin`. Add `--ignore-immutable` only if an immutable-efivar error appears. `--microsoft` adds the Microsoft CAs (the Windows boot manager here is signed by the Windows UEFI CA 2023); `--firmware-builtin` keeps the firmware's own default db entries (Dell keys) so firmware-signed components keep loading.
4. (sudo) `sudo sbctl status` must show Setup Mode: Disabled; `sudo sbctl verify`; `ls -l /sys/firmware/efi/efivars/dbx-*` must be non-empty (do not clear dbx).

### Phase 3: turn it on (planned)

1. Remove or reorder the stale unsigned GRUB firmware entry first: `sudo efibootmgr -b 0000 -B` (or `sudo efibootmgr -o <ids>` so a signed entry comes first). Keep a copy of `efibootmgr -v` before.
2. BIOS: Secure Boot ON, Deployed Mode. Afterwards re-check `sudo sbctl list-enrolled-keys` (toggling Custom Mode may restore factory keys on Dell; unverified).
3. Boot NixOS; `bootctl status` must report "Secure Boot: enabled (user)". Windows is reachable via F12.
4. LUKS asks for the passphrase once (PCR 7 changed). Re-seal the TPM to PCR 7 only: `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/nvme0n1p6`. The `tpm-reenroll` helper in `modules/common/programs/shells/shell-aliases.nix` currently hardcodes PCRs 0+2+7 and must be changed to 7 at this step.
5. In this same step switch `constants.emergencyAccess` off on all hosts (an initrd root shell defeats the Secure Boot threat model), set `services.lanzaboote.secureBoot = true;` in `hosts/nixos-laptop/default.nix` (its assertions then enforce emergencyAccess off) and rebuild.

### Phase 4: clean up GRUB leftovers

After a long stable period: `/boot/grub`, `/boot/kernels`, `/boot/EFI/NixOS-boot`, `grubx64.efi.old`, then drop the GC root. Not before; they are the fallback while Secure Boot is still OFF.

## Recovery

- lanzaboote boot fails while Secure Boot is OFF: press F12 and choose the old GRUB entry ("NixOS-boot"). It shows the frozen generations from the last GRUB install and works only while their store paths exist (hence the GC root).
- Boot fails with Secure Boot ON: enter the BIOS (admin password), disable Secure Boot, boot an older generation from the systemd-boot menu.
- Power loss during install / hash verification failure: boot an older generation, check `sbctl verify /boot/EFI/Linux/nixos-generation-*.efi`, delete corrupt files, `nixos-rebuild boot`. If nothing boots: live NixOS ISO with Secure Boot OFF, mount the ESP (`fsck.fat` if needed), `rm -fr /mnt/boot/EFI/Linux/nixos-generation-*.efi /mnt/boot/EFI/nixos`, `nixos-enter`, `nixos-rebuild boot --install-bootloader`. For the tmpfs root, mount the btrfs subvolumes as in `Documentation/troubleshooting/emergency-recovery-gnu-grub.md` section 1B; the key directory must be reachable as `/persist/var/lib/sbctl`. (`recover.sh` is GRUB-oriented and not adapted yet.)
- Restore the ESP from the Phase 0 archive: live ISO, `sudo mount /dev/nvme0n1p5 /mnt/esp && sudo tar -C /mnt/esp -xpf <esp-nixos.tar>` (check first what you overwrite).
- Back to factory keys: BIOS > Secure Boot > Expert Key Management > Custom Mode > Reset All Keys > Deployed Mode.
- Lost signing key: the keys are only needed to sign new boot files. Enter the BIOS, disable Secure Boot, `sbctl create-keys` again, repeat Phase 2/3 (the enrolled db then has to be replaced).

## Caveats

- lanzaboote describes itself as having "sharp edges"; the recovery path above matters.
- The stub measures kernel/initrd/cmdline into PCR 11/12/13; measured boot (pcrlock) is intentionally off (it limits the ESP to 4 generations).
- Recovery or installer ISOs need Secure Boot OFF once it is on.
- The new flake input builds the Rust UEFI stub locally (no binary cache is declared by lanzaboote), which costs build time on a cold cache.
