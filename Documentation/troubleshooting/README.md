# Recovering a NixOS host that won't boot

This folder holds the emergency kit for when a NixOS machine no longer boots:

| File | What it is |
|------|------------|
| `recover.sh` | The automated recovery script. Run it from a live USB. |
| `README.md` | This guide: every step, every prompt, what to do afterwards. |
| `emergency-recovery-gnu-grub.md` | The same recovery done by hand, if the script can't be used. |

## 0. Do you need the live USB at all?

| What you see at power-on | What to do |
|---|---|
| The GRUB menu shows, but NixOS fails later (black screen, emergency mode, crash) | **No USB needed.** In GRUB choose *"NixOS - All configurations"*, pick an older generation, boot it, then fix the config and rebuild normally. |
| GRUB shows `error: symbol '…' not found`, `grub rescue>` or a `minimal bash-like` prompt | Live USB → `recover.sh` (most likely `--grub-only`, see [section 6](#6-grub-says-symbol--not-found-after-a-successful-rebuild)) |
| No GRUB at all, the machine goes straight to Windows or the firmware | Live USB → `recover.sh` |

## 1. Before: what you need

- Another computer to write the USB stick (Windows or Linux).
- A USB stick of at least 4 GB. **It will be wiped.**
- The **LUKS passphrase**, if the host's disk is encrypted (`nixos-laptop` is, `nixos-desktop` is not).
  TPM/FIDO2 unlocking doesn't work from a live USB, so the passphrase (or recovery key) is required.
- Internet on the broken machine: Wi-Fi name and password, an Ethernet cable, or a phone with USB tethering.

## 2. Make the live USB (this is where it usually goes wrong)

1. Download the **graphical** NixOS ISO (KDE) from <https://nixos.org/download>.
   The minimal ISO works too, but it has no `nmtui` and no browser, so Wi-Fi means `wpa_cli` by hand.
2. Write it **as an exact image**:
   - **Rufus (Windows):** select the ISO, leave *partition scheme* and *file system* as they are (they are
     ignored), press *Start*, and when the *"ISOHybrid image detected"* popup appears choose
     **"Write in DD Image mode"**. Do **not** use the recommended ISO mode.
   - **Etcher:** works as is (always writes the exact image and verifies it).
   - **Linux:** `sudo dd if=nixos-graphical-….iso of=/dev/sdX bs=4M status=progress conv=fsync`
     (check `/dev/sdX` with `lsblk` first - `dd` overwrites whatever you point it at).
3. If Windows afterwards says the stick is unreadable or offers to format it: **ignore it, don't format.**
   Windows just can't read the stick's `iso9660` filesystem.

Why not Rufus' ISO mode: it rebuilds the stick as a FAT partition and copies the files over. The label
gets cut to 11 characters (`NIXOS-MINIM`), the live system can't find itself and stops with
`Timed out waiting for device /dev/disk/by-label/nixos-…` in **emergency mode**. ISO mode is meant for
Windows ISOs; Linux ISOs are "hybrid" disk images that must be copied byte for byte.

## 3. Boot the live USB

1. Plug the stick in, power on and open the one-time boot menu (**F12** on the Dell laptop; F10/F11/Esc
   on other machines).
2. Pick the USB entry (e.g. *"UEFI SMI Corporation USB DISK"*). Always the **UEFI** one.
3. In the USB's own menu pick the **default entry (newest kernel)**. Don't pick the LTS kernel: new
   hardware like the laptop needs a recent kernel. Use a *nomodeset* entry only if the screen stays black.
4. Connect to the internet: KDE network icon (bottom right) → your Wi-Fi. Ethernet and phone tethering
   connect by themselves.
5. Open **Konsole**. To copy commands from this guide more comfortably, either open it in Firefox on the
   live system, or SSH in from another computer:
   ```bash
   passwd                      # temporary password for the 'nixos' user (gone after reboot)
   sudo systemctl start sshd
   ip -4 -br addr              # the IP to connect to: ssh nixos@<ip>
   ```

## 4. Run the script

```bash
nix-shell -p git                                # only if git is missing
git clone -b develop https://github.com/nicolkrit999/nix
cd nix
./Documentation/troubleshooting/recover.sh --branch develop
```

- `-b develop`: clone the branch that contains the newest version of the recovery script.
- `--branch develop`: build the system from `develop`. Leave it out to build `main` (the default).
- No `sudo` needed: the script switches to root by itself.
- The hostname is detected from the disk. Pass it only to override: `recover.sh nixos-laptop`.

### What it asks, in order, and what to answer

| Prompt | Answer |
|---|---|
| *No internet … Open nmtui to connect?* | **Enter** and connect, or connect another way and press Enter. Only appears without internet. |
| *Unlock /dev/nvme0n1p6 (1.8T)?* | **Enter**, then type the **LUKS passphrase**. Only on encrypted hosts. Answer `n` for encrypted partitions that aren't this NixOS (e.g. a data disk). |
| *Unlocking failed. Try again?* | Enter and retype it. |
| *More than one NixOS installation found. Which one?* | Type the number. Only if several disks have NixOS. |
| *You asked for 'X', but the system on disk calls itself 'Y'. Build 'X' anyway?* | Normally **`n`**: re-run without a hostname. Only if you passed a hostname that doesn't match. |
| *Which flake should be built?* | The number of your repo (`/home/krit/nix`). Only if several flakes are found. |
| **Ready to repair** summary + *Go ahead?* | **Check it first** (see below), then **Enter**. Answering `n` stops with everything still mounted. |
| *The rebuild failed. What now?* | `1` (sandbox off) first - it fixes the usual chroot errors. `3` opens a shell to fix things by hand, `4` stops. |
| *Reboot now?* | **Enter**. |

In the **Ready to repair** summary, check:

- `host:` is the machine you're repairing (`nixos-laptop` / `nixos-desktop`).
- `flake:` is `/home/krit/nix`.
- `mounted:` has `/`, `/nix`, `/home`, `/persist`, `/var/log` and **`/boot` on the NixOS boot partition**
  (laptop: `nvme0n1p5`, label `NIXOS-BOOT`; not Windows' boot partition).

Normal things you'll see: lines about `setting up /etc`, sops or systemd while it enters the chroot;
skipped mounts for Windows (`ntfs3`) and the NAS shares (`noauto`); a long download/build.

### Options

| Option | Use it when |
|---|---|
| `--branch NAME` | Build another branch than `main` (e.g. `develop`). |
| `--keep-changes` | Uncommitted changes in the on-disk repo are **needed** for the build. Default is to stash them. |
| `--grub-only` | The rebuild already worked, but GRUB stops with `symbol … not found`. No internet needed. |
| `--shell` | Mount everything and open a shell inside the installed system, to fix something by hand. |
| `--skip-mount` | You mounted everything under `/mnt` yourself. |
| `--flake PATH` | The repo isn't found automatically (path as seen from the installed system). |
| `-y` | Accept every default answer (the passphrase is still asked). |

## 5. After: reboot and back in NixOS

- **The USB stick can stay in.** The firmware starts its NixOS entry before the USB. If the live system
  comes up again anyway, remove the stick and reboot.
- You should get the **GRUB menu → LUKS passphrase → login screen**.
- **No bootloader rebuild is needed afterwards.** The script already ran
  `nixos-rebuild boot --install-bootloader` and refreshed every GRUB copy.
- If the script stashed uncommitted changes, get them back:
  ```bash
  cd ~/nix && git stash list && git stash pop
  ```
- The system now runs the branch you built (`--branch`). Rebuild normally from now on.
- Optional check: `sudo efibootmgr` shows the firmware boot order. The first entry should be NixOS'
  (`NixOS-boot`).

## 6. GRUB says `symbol '…' not found` after a successful rebuild

This is what broke `nixos-laptop` on 2026-10-08.

**Cause.** GRUB has two parts that must come from the same version: the program the firmware starts
(an `.efi` file) and the modules in `/boot/grub/x86_64-efi/`. With `efiInstallAsRemovable = true`, NixOS
only updates `EFI/BOOT/BOOTX64.EFI`. The laptop's firmware however starts its first boot entry
*NixOS-boot* → `EFI/NixOS-boot/grubx64.efi`, a copy from the original install that nothing updated any
more. When `develop` moved to nixos-unstable, GRUB was updated: new modules, old program → `symbol … not
found` before the menu, on every boot, no matter how often the system is rebuilt.

**Fix from the live USB:**
```bash
./Documentation/troubleshooting/recover.sh --grub-only
```
It unlocks and mounts the disk, replaces every out-of-date NixOS GRUB copy (`EFI/BOOT/`, `EFI/NixOS*/`)
with the current one (keeping a `.old` backup next to it), shows which entry the firmware starts first,
and unmounts. Windows' boot manager, systemd-boot and other distros' GRUB are never touched.

Already booted into NixOS (e.g. via F12 → the drive's second "UEFI …" entry, which starts
`EFI/BOOT/BOOTX64.EFI`)? Then this does the same without the USB:
```bash
sudo cp /boot/EFI/NixOS-boot/grubx64.efi /boot/EFI/NixOS-boot/grubx64.efi.old
sudo cp /boot/grub/x86_64-efi/core.efi /boot/EFI/NixOS-boot/grubx64.efi
```

**Prevention.** `modules/nixos/toplevel/boot.nix` syncs `EFI/NixOS*/grubx64.efi` with the freshly
installed GRUB on every rebuild (`boot.loader.grub.extraInstallCommands`; it prints
`boot.nix: refreshed stale GRUB copy …` when it had to), and `recover.sh` does the same check after
every repair.

## 7. Problems seen before

| Symptom | Cause / fix |
|---|---|
| Live USB stops in **emergency mode**, `journalctl -xb` says `Timed out waiting for device /dev/disk/by-label/nixos-…` | Stick written in Rufus ISO mode (`lsblk -f` shows it as `vfat NIXOS-MINIM`). Rewrite it in DD mode ([section 2](#2-make-the-live-usb-this-is-where-it-usually-goes-wrong)). |
| Live USB boot fails only with the LTS kernel | Hardware too new for it. Use the default (newest) kernel entry. |
| GRUB `symbol '…' not found` | [Section 6](#6-grub-says-symbol--not-found-after-a-successful-rebuild): `recover.sh --grub-only`. |
| `mount: … source write-protected, mounted read-only` when mounting a partition **by hand** | It is still mounted read-only somewhere (`findmnt -S /dev/nvme0n1p5` shows it, maybe twice). Unmount every layer, then mount again. The SSD isn't broken. |
| Script: *No NixOS installation found* | The encrypted partition wasn't unlocked (answered `n`, or wrong passphrase). Check with `lsblk -f`. |
| Rebuild fails with sandbox / namespace errors | Choose *retry with the Nix sandbox off*. |
| Script: *The flake has no hosts/X* | Wrong hostname, or the branch doesn't have that host yet - check `--branch`. |

## 8. How the script works (short version)

It finds everything on the disk itself, so nothing about a host is hardcoded:

1. Unlocks LUKS partitions (if any).
2. Looks for a Nix store on every Linux filesystem and reads `fstab` and `hostname` from the newest system
   generation stored there - the same information the machine uses to boot.
3. Mounts exactly what that `fstab` says (tmpfs root, btrfs subvolumes, the right boot partition in a
   dual boot), skipping Windows, network shares and `noauto` mounts.
4. In the on-disk repo: stashes uncommitted changes, checks out the branch and fast-forwards it from the
   fresh clone on the USB.
5. Runs `nixos-rebuild boot --install-bootloader` inside the installed system (`nixos-enter`).
6. Replaces stale GRUB copies, unmounts, closes LUKS and offers to reboot.

Details are in the comments at the top of `recover.sh` (`recover.sh --help`). Doing it all by hand:
`emergency-recovery-gnu-grub.md`.
