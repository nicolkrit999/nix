# Recovering a NixOS host that won't boot

This folder holds the emergency kit for when a NixOS machine no longer boots:

| File | What it is |
|------|------------|
| `recover.sh` | The automated recovery script. Run it from a live USB. Works for GRUB hosts and for lanzaboote (Secure Boot) hosts. |
| `README.md` | This guide: every step, every prompt, what to do afterwards. |
| `emergency-recovery-gnu-grub.md` | The same recovery done by hand, if the script can't be used (GRUB and lanzaboote). |

## Which bootloader does my host use?

| Host | Bootloader | Disk |
|---|---|---|
| `nixos-laptop` | **lanzaboote** (signed systemd-boot, Secure Boot ON) | LUKS + tmpfs root (impermanence) |
| `nixos-desktop` | **lanzaboote** (signed systemd-boot, Secure Boot ON) | no LUKS, tmpfs root (impermanence) |

The script finds out by itself (it asks the flake, else looks at the boot partition), so the same command works
for both. The tables below say which row applies to which bootloader.

## 0. Do you need the live USB at all?

| What you see at power-on | What to do |
|---|---|
| **GRUB host:** the GRUB menu shows, but NixOS fails later (black screen, emergency mode, crash) | **No USB needed.** In GRUB choose *"NixOS - All configurations"*, pick an older generation, boot it, then fix the config and rebuild normally. |
| **lanzaboote host:** the systemd-boot menu shows (a list of NixOS generations), but NixOS fails later | **No USB needed.** Pick an older generation in that menu (arrow keys, Enter), boot it, then fix the config and rebuild normally. The older entries are signed too, so they boot with Secure Boot ON. |
| **lanzaboote host:** the firmware refuses to start the loader (Secure Boot / security violation message) | No USB needed first: enter the BIOS (admin password), switch Secure Boot **off**, boot an older generation from the systemd-boot menu. If no menu shows at all, use the USB row below. |
| GRUB shows `error: symbol '…' not found` (**GRUB hosts only**) | Live USB → `recover.sh --grub-only` (see [section 4](#4-run-the-script)) |
| GRUB shows `grub rescue>` or a `minimal bash-like` prompt | Live USB → `recover.sh` |
| No boot menu at all (no GRUB, no systemd-boot), the machine goes straight to Windows or the firmware | Live USB → `recover.sh` |

## 1. Before: what you need

- Another computer to write the USB stick (Windows or Linux).
- A USB stick of at least 4 GB. **It will be wiped.**
- The **LUKS passphrase**, if the host's disk is encrypted (see the table above).
  TPM/FIDO2 unlocking doesn't work from a live USB, so the passphrase (or recovery key) is required.
- **lanzaboote hosts only:** the BIOS admin password (to switch Secure Boot off and on), and the encrypted archive of
  the Secure Boot signing keys from the password manager. You normally do **not** need the archive: the keys are on
  the host's own disk under `pkiBundle` (`/persist/var/lib/sbctl` by default). It is only needed if that directory is missing or damaged
  (the script checks and tells you before it changes anything).
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

0. **lanzaboote host: switch Secure Boot OFF in the BIOS first**, then boot the USB. A stock NixOS
   ISO is not signed with your keys, so the firmware refuses it while Secure Boot is on. The BIOS setup key
   (often **F2** or **Del**) and the menu path are vendor specific; you need the admin password. Normally the enrolled keys stay in
   the firmware while the setting is off, so afterwards you only switch it back on ([section 5](#5-after-reboot-and-back-in-nixos)).
   Do **not** delete keys or "reset to factory" in the BIOS for this. GRUB hosts skip this step.
1. Plug the stick in, power on and open the one-time boot menu (usually **F12**, **F10**, **F11** or
   **Esc**).
2. Pick the USB entry. Always the **UEFI** one.
3. In the USB's own menu pick the **default entry (newest kernel)**. Don't pick the LTS kernel: new
   hardware needs a recent kernel. Use a *nomodeset* entry only if the screen stays black.
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

### Which command?

| What you saw at power-on | Run |
|---|---|
| GRUB error `symbol '…' not found` (GRUB host) | `recover.sh --grub-only` - fast, no rebuild. If GRUB still fails afterwards, run the full `recover.sh`. |
| `grub rescue>`, `minimal bash-like`, or no GRUB at all (GRUB host) | `recover.sh` (full run) |
| lanzaboote host: no boot menu, loader files missing or corrupt, power loss during a bootloader install | `recover.sh` (full run). `--grub-only` does not apply there: it says so and exits without touching anything. |
| Not sure | `recover.sh` (full run). On a GRUB host it ends with the same step `--grub-only` does, so it is always safe - just slower, and it needs internet. |

Both need the clone below (that's where the script is), so connect to the internet either way.

### Commands

```bash
nix-shell -p git                                # only if git is missing
git clone -b develop https://github.com/nicolkrit999/nix
cd nix
./Documentation/troubleshooting/recover.sh --branch develop     # full run
./Documentation/troubleshooting/recover.sh --grub-only          # OR (GRUB hosts only): just the stale-GRUB fix
```

Run **one** of the last two lines, per the table above.

- `-b develop`: clone the branch that contains the newest version of the recovery script.
- `--branch develop`: build the system from `develop`. Leave it out to build `main` (the default).
- No `sudo` needed: the script switches to root by itself.
- The hostname is detected from the disk. Pass it only to override: `recover.sh <hostname>`.

### What it asks, in order, and what to answer

| Prompt | Answer |
|---|---|
| *No internet … Open nmtui to connect?* | **Enter** and connect, or connect another way and press Enter. Only appears without internet. |
| *Unlock /dev/<luks-device> (size)?* | **Enter**, then type the **LUKS passphrase**. Only on encrypted hosts. Answer `n` for encrypted partitions that aren't this NixOS (e.g. a data disk). |
| *Unlocking failed. Try again?* | Enter and retype it. |
| *More than one NixOS installation found. Which one?* | Type the number. Only if several disks have NixOS. |
| *You asked for 'X', but the system on disk calls itself 'Y'. Build 'X' anyway?* | Normally **`n`**: re-run without a hostname. Only if you passed a hostname that doesn't match. |
| *Which flake should be built?* | The number of your repo (e.g. `/home/<user>/nix`). Only if several flakes are found. |
| **Ready to repair** summary + *Go ahead?* | **Check it first** (see below), then **Enter**. Answering `n` stops with everything still mounted. |
| *The Secure Boot signing key is NOT in … on the installed system* (lanzaboote only) | Default is **stop** (Enter). Restore the key archive into place (option 2 opens a shell on the live system for that), then re-run. See "The lanzaboote key preflight" below. Never create new keys unless the old ones are really lost. |
| *Type CREATE NEW KEYS to confirm* (lanzaboote only) | Only if the key archive is lost. Anything else goes back. The new keys do not match the firmware: Secure Boot must stay off and the key enrollment and Secure Boot steps of [Adding lanzaboote](../installation/lanzaboote.md) (phases 2 and 3) must be repeated. |
| *The rebuild failed. What now?* | `1` (sandbox off) first - it fixes the usual chroot errors. `3` opens a shell to fix things by hand, `4` stops. |
| *Create this firmware entry now?* (lanzaboote only, only if no entry points at the NixOS boot partition) | **Enter** (= no) unless the F12 menu really shows no way to start NixOS. It prints the exact `efibootmgr -c` command first. |
| *A boot file is unsigned … Unmount and finish anyway?* (lanzaboote only) | Default **no**: everything stays mounted so you can look. See section 5. |
| *Reboot now?* | **Enter**. |

In the **Ready to repair** summary, check:

- `host:` is the machine you're repairing.
- `flake:` is the path of your repo on the installed system.
- `boot:` is the bootloader the files on the disk look like (`grub`, `lanzaboote`, `other`). This is only the first
  guess: right after you confirm and the repo is updated, the script asks the flake (`nix eval` in the chroot, it
  can take a minute) and prints `Target bootloader: … (from the flake (<host>))`. If the flake cannot be evaluated
  it says so and uses the disk guess (`from the disk (…)`). If both disagree it follows the flake.
- `mounted:` has `/`, `/nix`, `/home`, `/persist`, `/var/log` and **`/boot` on the NixOS boot partition**
  (not Windows' boot partition).

Normal things you'll see: lines about `setting up /etc`, sops or systemd while it enters the chroot;
skipped mounts for Windows (`ntfs3`) and the NAS shares (`noauto`); a long download/build.

### The lanzaboote key preflight (lanzaboote targets only, before the rebuild)

lanzaboote signs every boot file with a private key. The install hook runs inside the rebuild and needs that key;
if it is missing it fails at the very first key read, **before** anything is written to the boot partition (safe,
but the rebuild fails). The script therefore checks first:

1. Where the keys should be: the flake's `boot.lanzaboote.pkiBundle`; else `keydir` in the newest generation's
   `/etc/sbctl/sbctl.conf`; else the default (`/persist/var/lib/sbctl` if the disk has a `/persist`, otherwise
   `/var/lib/sbctl`). The path is printed with where it came from.
2. Whether `<pkiBundle>/keys/db/*.key` and `*.pem` exist on the mounted system (PK/KEK/GUID missing is only a
   warning: they are needed to enroll keys again, not to sign).
3. If the keys are not at the configured path but exist under `/persist` (a bind-mounted path such as
   `/var/lib/sbctl` on an impermanence host), they are bind-mounted into place, as the system does at boot.
4. The boot partition's free space (warns under 150 MB; one kernel + initrd set needs about 160 MB) and whether the
   live system itself runs with Secure Boot enforcing.

If the key is missing it explains and offers, **default = stop**, never automatic (and `-y` also stops):
restore the archive yourself (a shell on the live system opens in the right directory; extract with
`tar -xpf <archive> -C /mnt/persist/var/lib/sbctl`, keep it root-only, `exit`, it checks again), continue anyway
(the rebuild will fail), or create new keys with `sbctl create-keys` in the chroot after you type
`CREATE NEW KEYS`. New keys do not match the public key enrolled in the firmware: with Secure Boot ON nothing
signed with them boots. Only use that option if the old keys are truly lost, and then follow "Lost signing key" in
[lanzaboote.md](../usage/secure-boot/lanzaboote.md).

### Options

| Option | Use it when |
|---|---|
| `--branch NAME` | Build another branch than `main` (e.g. `develop`). |
| `--keep-changes` | Uncommitted changes in the on-disk repo are **needed** for the build. Default is to stash them. |
| `--grub-only` | **GRUB hosts only.** The rebuild already worked, but GRUB stops with `symbol … not found`. Skips internet check, git and rebuild. On a lanzaboote host it prints that it does not apply, what to use instead (the full run, or `--shell`) and exits without changing anything. |
| `--shell` | Mount everything and open a shell inside the installed system, to fix something by hand. |
| `--skip-mount` | You mounted everything under `/mnt` yourself. |
| `--flake PATH` | The repo isn't found automatically (path as seen from the installed system). |
| `-y` | Accept every default answer (the passphrase is still asked). |

### Which environment does what

Everything below is detected from the disk; nothing needs to be told to the script.

| Environment | LUKS | `/` | Bootloader | Signing keys (lanzaboote) | Notes |
|---|---|---|---|---|---|
| LUKS + impermanence + lanzaboote | unlocked first (passphrase) | tmpfs, `/persist` etc. mounted from the fstab | lanzaboote | `pkiBundle` = `/persist/var/lib/sbctl` (a real btrfs subvolume, reachable in the chroot; no bind mount needed) | full flow with key preflight and `sbctl verify` |
| no LUKS + impermanence + lanzaboote | none, the unlock step is skipped | tmpfs + btrfs subvolumes | lanzaboote | `pkiBundle` = `/persist/var/lib/sbctl` | key preflight and `sbctl verify`; a Windows on another disk's ESP is not touched |
| LUKS, no impermanence, lanzaboote | unlocked first | on disk | lanzaboote | whatever the flake's `pkiBundle` says; the module default is `/persist/var/lib/sbctl`, a host without `/persist` typically sets `/var/lib/sbctl`, found on the root filesystem | same flow; if the keys only exist under `/persist` they are bound to the configured path |
| no LUKS, no impermanence, GRUB | none | on disk | GRUB | not used | stale-GRUB-copy check at the end, `--grub-only` available |
| dual boot, several disks | only the partitions you accept | - | either | - | only the boot partition named by the NixOS fstab (`/boot`) is mounted and touched; Windows' partitions (`ntfs3`) and other disks are skipped. The firmware-entry check compares the **PARTUUID** of that boot partition, so entries for other disks' ESPs never count |
| bootloader switched in the flake (e.g. GRUB → lanzaboote), disk still the old one | - | - | follows the **flake** | as above | the script prints that the flake and the disk disagree and follows the flake |

## 5. After: reboot and back in NixOS

- **The USB stick can stay in.** The firmware starts its NixOS entry before the USB. If the live system
  comes up again anyway, remove the stick and reboot.
- **GRUB host:** you should get the **GRUB menu → LUKS passphrase (if any) → login screen**.
- **lanzaboote host:** you should get the **systemd-boot menu → LUKS (TPM unlock or passphrase) → login screen**.
- **No bootloader rebuild is needed afterwards.** The script already ran
  `nixos-rebuild boot --install-bootloader` and, on GRUB, refreshed every GRUB copy.
- If the script stashed uncommitted changes, get them back:
  ```bash
  cd ~/nix && git stash list && git stash pop
  ```
- The system now runs the branch you built (`--branch`). Rebuild normally from now on.
- Optional check: `sudo efibootmgr` shows the firmware boot order. The first entry should be NixOS'
  (GRUB hosts: `NixOS-boot`; lanzaboote hosts: the `UEFI <disk>` fallback entry that starts
  `\EFI\BOOT\BOOTX64.EFI`, which is systemd-boot there).

### lanzaboote hosts: what the script printed, and what to do now

1. **Re-enable Secure Boot in the BIOS** (you switched it off for the live USB). The keys normally stayed enrolled,
   so nothing else is needed; the boot files the script wrote are signed with the key on the disk. Check once back
   in NixOS: `bootctl status` says *Secure Boot: enabled (user)*.
2. **`sbctl verify` summary.** The script runs it in the chroot and fails loudly (and asks before unmounting) only
   if a file the firmware has to verify is unsigned: `EFI/Linux/nixos-*.efi` (the stubs), `EFI/BOOT/BOOTX64.EFI` or
   `EFI/systemd/systemd-bootx64.efi`, or if no stub exists at all. **The other red crosses are expected, not an
   error:** `EFI/nixos/kernel-*.efi` and `initrd-*.efi` (the signed stub checks them by hash) and GRUB leftovers
   (`EFI/NixOS-boot/grubx64.efi`, `/boot/grub/…`, `/boot/kernels/…`, which are dead weight under Secure Boot; see
   the GRUB cleanup runbook in [lanzaboote.md](../usage/secure-boot/lanzaboote.md)). If `sbctl` gives no verdict at all it says so,
   which is a warning, not a failure: run `sudo sbctl verify` yourself after booting.
3. **Firmware entry.** lanzaboote writes no EFI variables. If the firmware lost its entries (NVRAM reset) the
   script notices that no boot entry points at the NixOS boot partition and prints the exact
   `efibootmgr -c -d /dev/<disk> -p <n> -l '\EFI\BOOT\BOOTX64.EFI' -L 'NixOS lanzaboote'` (disk and partition
   number come from the mounted `/boot` device, not from a fixed name) and asks, default no.
4. **TPM (LUKS hosts).** The TPM unlocks the disk only while PCR 7 is the same as when it was sealed (same keys,
   same Secure Boot state). If the passphrase is asked at the next boot, type it, log in and re-seal:
   ```bash
   sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 <luks-device>
   ```
   (the script prints the device it unlocked). The `tpm-reenroll` shell helper does the same.
5. If you let the script create **new keys**: they are not enrolled. Keep Secure Boot off and repeat phases 2 and 3 of
   [Adding lanzaboote](../installation/lanzaboote.md).

## 6. GRUB says `symbol '…' not found` after a successful rebuild

**GRUB hosts only.** There is no GRUB program or GRUB copy to go stale on a lanzaboote host, and `--grub-only`
refuses to run on it.

**Cause.** GRUB has two parts that must come from the same version: the program the firmware starts
(an `.efi` file) and the modules in `/boot/grub/x86_64-efi/`. With `efiInstallAsRemovable = true`, NixOS
only updates `EFI/BOOT/BOOTX64.EFI`. A firmware can however start its first boot entry
*NixOS-boot* → `EFI/NixOS-boot/grubx64.efi`, a copy from the original install that nothing updated any
more. After a GRUB update: new modules, old program → `symbol … not
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

## 7. Common problems

| Symptom | Cause / fix |
|---|---|
| Live USB stops in **emergency mode**, `journalctl -xb` says `Timed out waiting for device /dev/disk/by-label/nixos-…` | Stick written in Rufus ISO mode (`lsblk -f` shows it as `vfat NIXOS-MINIM`). Rewrite it in DD mode ([section 2](#2-make-the-live-usb-this-is-where-it-usually-goes-wrong)). |
| Live USB boot fails only with the LTS kernel | Hardware too new for it. Use the default (newest) kernel entry. |
| GRUB `symbol '…' not found` | [Section 6](#6-grub-says-symbol--not-found-after-a-successful-rebuild): `recover.sh --grub-only` (GRUB hosts only). |
| Live USB won't start with *Secure Boot violation* / *Access Denied* (lanzaboote host) | Secure Boot is still on. Switch it off in the BIOS first ([section 3](#3-boot-the-live-usb), step 0), switch it on again afterwards. |
| Script: *The Secure Boot signing key is NOT in …* | The key directory is missing on the installed system. Restore the key archive ([section 4](#the-lanzaboote-key-preflight-lanzaboote-targets-only-before-the-rebuild)); do not create new keys unless the old ones are lost. |
| Script: *--grub-only does not apply* | The host boots through lanzaboote. Run the full `recover.sh`. |
| `sbctl verify` shows several red crosses | Only `EFI/Linux/nixos-*.efi`, `EFI/BOOT/BOOTX64.EFI` and `EFI/systemd/systemd-bootx64.efi` must be signed. `EFI/nixos/kernel-*` and GRUB leftovers are expected unsigned. |
| LUKS asks for the passphrase after a lanzaboote repair | PCR 7 changed (Secure Boot state or keys). Re-seal, see section 5 point 4. |
| `mount: … source write-protected, mounted read-only` when mounting a partition **by hand** | It is still mounted read-only somewhere (`findmnt -S <partition>` shows it, maybe twice). Unmount every layer, then mount again. The SSD isn't broken. |
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
5. Decides the target bootloader (grub | lanzaboote | other): `nix eval` of the flake in the chroot is the main
   signal, the files on the disk are the fallback (`/etc/sbctl/sbctl.conf` in the newest generation, or signed
   stubs + systemd-boot on the boot partition mean lanzaboote; a hybrid boot partition with GRUB leftovers still
   counts as lanzaboote; GRUB modules without those mean GRUB). lanzaboote: runs the key preflight.
6. Runs `nixos-rebuild boot --install-bootloader` inside the installed system (`nixos-enter`).
7. GRUB: replaces stale GRUB copies. lanzaboote: `sbctl verify` summary and the firmware-entry check
   (no stale-GRUB step, it would target files that are not used).
8. Unmounts, closes LUKS and offers to reboot.

Details are in the comments at the top of `recover.sh` (`recover.sh --help`). Doing it all by hand:
`emergency-recovery-gnu-grub.md`.
