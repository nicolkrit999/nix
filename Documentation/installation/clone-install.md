# Clone install: reinstall nixos-desktop / nixos-laptop on new hardware

This installs an existing host (`nixos-desktop` or `nixos-laptop`) onto another PC from a live USB stick: same config, same users, same secrets, new disk. It is a separate path from [disko](./disko.md) and [manual](./manual.md), which set up a host from scratch. Follow-up pages:

- [Post-install checklist](./clone-post-install.md) (first boot, Secure Boot, TPM, things to fix on new hardware)
- [Retire the old machine and promote the clone](./clone-retire-and-promote.md)

Contents: [When to use it](#when-to-use-it) | [Prerequisites](#prerequisites) | [Build or download the ISO](#build-or-download-the-iso) | [Make the key bundle](#make-the-key-bundle) | [Boot the stick](#boot-the-stick) | [Run the installer](#run-the-installer) | [Fallback without the ISO](#fallback-without-the-custom-iso) | [Known unverified items](#known-unverified-items)

## When to use it

| Situation | Use |
|---|---|
| A second PC next to the original (both exist for a while) | the `-2` variant (default): installs `<host>-2` |
| Replacing a PC (old one is retired or sold) | the `-2` variant first, then [retire and promote](./clone-retire-and-promote.md) |
| Installing a different or brand-new host | not this page: [disko](./disko.md) or [manual](./manual.md) |

How it works: `nixosConfigurations.<host>-2` is the original's whole config with only `networking.hostName` changed and the disk/hardware layer replaced by a generic one (filesystems found by label, broad initrd modules, both CPU microcodes). The original host files are never modified by the install. Everything keyed on `networking.hostName` follows the new name: the tailnet node name and the borg repository folder. Everything keyed on `myconfig.constants.hostname` stays the original's, so the same sops files, the same host key and the same per-host module selections apply.

Because the clone is evaluated from the same files as the original, an edit in `hosts/<host>/` changes both until the original is retired.

Supported hosts: only the two pairs `nixos-desktop`/`nixos-desktop-2` and `nixos-laptop`/`nixos-laptop-2`. Target hardware must be x86_64 with UEFI.

## Prerequisites

1. **`develop` merged into `main`.** The installer clones only `main` (no branch option). The `-2` hosts and the installer scripts must be on `main`.
2. **Tailscale and the NAS reachable.** The installer joins the tailnet on the live system itself (with the sops `tailscale_key`) and then uses the Attic binary cache on the NAS through it. If Attic cannot be reached the install still works but compiles whatever the public caches lack, which can take very long.
3. **The key bundle** on the Ventoy stick, see [Make the key bundle](#make-the-key-bundle), and its passphrase.
4. **Internet on the target PC.** Wired works at once. Wi-Fi: `nmtui` (or `nmcli device wifi connect SSID password PASSWORD`) on the live system; `clone-install` waits and offers `[r]etry` / `[q]uit` until the repository is reachable.
5. **A disk to install onto**, at least 68 GiB in one piece (4 GiB boot partition + 64 GiB root). Layout the installer creates:

   | Part | Layout |
   |---|---|
   | Boot | 4 GiB FAT32, partition name and label `NIXOS-BOOT` |
   | Root, `nixos-desktop` | btrfs, label `nixos`, subvolumes `@persist` `@home` `@nix` `@log`; `/` is a 4 GiB tmpfs; no LUKS |
   | Root, `nixos-laptop` | the same btrfs inside LUKS2 (partition name `nixos-luks`, mapper `cryptroot`) |

   LUKS follows the host config, not a prompt: the laptop is always encrypted, the desktop never.
6. **Free space next to Windows** (only if you keep Windows): shrink the Windows volume in Windows first (Disk Management, Shrink Volume, leave it unallocated; turn off Fast Startup and BitLocker beforehand). The installer never resizes NTFS.
7. **Secure Boot firmware state:** Setup Mode before the install, see [Boot the stick](#boot-the-stick).

## Build or download the ISO

The ISO is a custom NixOS live image: it carries every tool the installer needs, NetworkManager (`nmtui`) for Wi-Fi, and the laptop's kernel package set (the same, cached kernel the laptop runs, chosen so newer hardware has a recent kernel). It is not a `nixosConfiguration`; it only exists as a flake package.

```bash
nix build .#installer-iso          # in the repo, on an x86_64-linux machine
ls result/iso/                     # clone-installer-x86_64-linux.iso
sha256sum result/iso/*.iso
```

Keep the built ISO and its `sha256` in the `installer-iso` folder on the NAS, next to a copy of the key bundles. To use an existing copy, fetch it from there and verify it before writing it to the stick:

```bash
sha256sum -c <iso-name>.sha256     # or compare sha256sum output with the stored value
```

Put the ISO on a [Ventoy](https://www.ventoy.net) stick by copying it onto Ventoy's data partition. Rebuild the ISO when you want a newer kernel for new hardware; the installer itself always fetches the latest `main` at run time, so a stale ISO still installs the current config.

## Make the key bundle

The bundle carries what the clone needs to decrypt the existing sops secrets: the original host's SSH host key and the user age key, as one passphrase-encrypted `age` file. It does **not** contain Secure Boot (sbctl) keys: the clone creates its own.

Run it on the **original** machine, from the repo:

```bash
nix run .#make-bundle -- --host nixos-desktop --out-dir /path/to/ventoy-data-partition
# or: --host nixos-laptop
```

- The host key is root-only; the script asks for `sudo` itself (running the whole command as root works too).
- It asks for a **bundle passphrase** in one of two ways: type your own (age asks twice to confirm), or press Enter on the first prompt and age generates a passphrase and prints it once on the terminal. Either way, store it in your password manager, never on the stick.
- Keys are staged only on a tmpfs, shredded afterwards; the only file written to disk is `<host>-clone-bundle.tar.age`. It refuses to overwrite an existing file unless `--force` is given.
- Check the contents without extracting to disk: `age -d <file> | tar -tf -` (lists `host/ssh_host_ed25519_key`, `host/ssh_host_ed25519_key.pub`, `user/keys.txt`, `meta.txt`).
- Put one copy on the Ventoy stick (the installer scans every attached stick for `*.age`) and a backup copy in the NAS `installer-iso` folder. The bundle cannot be fetched from the NAS during the install, because joining the tailnet needs the host key that is inside the bundle.

The bundle is as sensitive as the original host: whoever has it and the passphrase can decrypt every secret in the repo. Delete stick copies when you are done.

## Boot the stick

1. **Firmware into Secure Boot Setup Mode** (both hosts use lanzaboote). In the firmware setup clear/delete the Platform Key: look for "Reset to Setup Mode", "Clear Secure Boot keys" or "Delete all variables"; on some boards switch Secure Boot mode to "Custom" first. Secure Boot itself may stay on or off; only Setup Mode matters. The installer enrolls the new keys together with the Microsoft keys, so Windows and option ROMs keep working. Turn Secure Boot **on** only after the install. Firmware menu names differ per vendor, see the firmware notes in [lanzaboote usage](../usage/secure-boot/lanzaboote.md).
2. Plug in the Ventoy stick, open the one-time boot menu, boot the stick in **UEFI** mode and pick the ISO in Ventoy's menu. In Setup Mode the firmware does not enforce signatures, which is what allows the unsigned ISO and Ventoy to start.
3. At the console prompt (user `nixos`, already logged in) run:

   ```bash
   clone-install
   ```

   It asks for `sudo` itself when needed.

## Run the installer

`clone-install` first checks that the repository is reachable (`[r]etry / [q]uit` loop), clones `main` shallow into `/run`, and starts the installer from that clone. Optional flags are passed through: `--dry-run`, `--host`, `--variant`, `--disk`, `--mode`, `--bundle`.

**Try it first with `clone-install --dry-run`:** it evaluates the config, shows the disk table and the partition plan, prints every action it would take and changes nothing. A dry run only warns at the Secure Boot gate and skips the final disk-name confirmation.

### Prompts, in order

| # | Prompt | Answer |
|---|---|---|
| 1 | `Which host do you want to install? [1-2]:` | `nixos-desktop` or `nixos-laptop` |
| 2 | `Variant? [1-2]:` | `2 (alongside)` installs `<host>-2` (default and safe). `same name (only after promotion)` installs `<host>` itself; the installer refuses it until the original has been [promoted](./clone-retire-and-promote.md) (its `/boot` must be the generic by-label one) |
| 3 | Secure Boot gate (only when the firmware is **not** in Setup Mode) | `[r]etry (re-read the firmware state) / [c]ontinue without enrollment / [q]uit:` - see below |
| 4 | disk table, then `Install onto which disk? [1-N]:` | pick the target disk |
| 5 | `Mode? [1-2]:` | `free-space` or `whole disk` - see below |
| 6 | `Type exactly 'no windows, wipe' to accept (anything else aborts):` | only for whole-disk mode on a disk that contains Windows, another OS or unrecognised data |
| 7 | `Type the disk name (/dev/...) to start the installation:` | the exact disk path shown in the plan. Everything before this point changes nothing |
| 8 | bundle: found automatically, else `Path to the bundle file (or 'q' to abort):` | when several bundles exist, the one named `<host>-clone-bundle.tar.age` is preferred, otherwise you choose |
| 9 | the `age` passphrase prompt | the bundle passphrase (asked once; the bundle is decrypted a single time into the tmpfs work dir) |
| 10 | `[p]aste a new key (default), [r]etry, [s]kip Tailscale, [q]uit:` (after a boxed explanation) | only if `tailscale up` fails with the key from the sops file (expired, revoked, single-use, or a network problem). `p` (or Enter) asks for the key with hidden input; `r` retries the same key (network problems); `s` continues without Tailscale; `q` aborts before any change. Up to 3 attempts, then only `s` or `q`. See [Tailscale auth key](#tailscale-auth-key) |
| 11 | `New LUKS passphrase for the disk:` and `Repeat LUKS passphrase:` | laptop only; this is the disk passphrase, entered at every boot until the TPM is re-enrolled |

**Tailscale auth key (prompt 10).** The installer first tries the `tailscale_key` stored in the sops file. If Tailscale rejects it, the installer prints a box with the reason and these steps, then asks:

1. Open <https://login.tailscale.com/admin/settings/keys> on any device and click **Generate auth key...**.
2. Turn **Reusable** on (so a retry can use it again) and leave **Ephemeral** off (an ephemeral machine vanishes from the tailnet when offline). Expiry of 1 day is enough, no tags needed.
3. Copy the key (it starts with `tskey-auth-`) and paste it at the hidden prompt (nothing is shown while you type).

The key is used for this install only: it is read from a tmpfs file, never put on a command line or printed, and shredded afterwards. The node identity is saved on the new system, so it joins the tailnet by itself after the reboot. Choosing `s` instead is safe: the install works. The Attic cache is probed separately before `nixos-install` and used whenever this network reaches it anyway (a VPN, the LAN, or a VM behind NAT on a host that is on the tailnet); if it does not, packages come from cache.nixos.org only and anything missing is compiled (slower) and you join manually after the first boot ([post-install, section 4](./clone-post-install.md#4-tailscale)). To stop the prompt for future installs, replace the stored key: [post-install, "Replace the stored Tailscale key"](./clone-post-install.md#replace-the-stored-tailscale-key).

**Secure Boot gate (prompt 3).** Runs before any disk is touched. It prints the BIOS steps for Setup Mode, then:

| Answer | Effect |
|---|---|
| `r` | re-reads the firmware state; if it is now in Setup Mode the install continues with enrollment (a firmware change needs a reboot, so for a real change use `q`, change the firmware, boot the stick again) |
| `c` | continue without enrollment: the keys are still created and the boot files signed, but you enroll them by hand after the first boot (the final checklist prints the commands) |
| `q` | exit, nothing modified |

**Disk table and modes.** The table lists every disk with a class: `empty`, `free-space` (a table with no OS and enough room), `windows`, `other-os`, `unknown`, plus the largest free block. A disk holding mounts of the running system (including the USB stick) is marked `[IN USE ...: not selectable]` and is always refused.

| Mode | What it does | Refused when |
|---|---|---|
| `free-space` | creates the boot and root partitions in the largest free block; existing partitions, including the Windows ESP, are verified identical afterwards and never touched | the disk is not GPT; no Windows ESP is found; the largest free block is under 68 GiB (the message tells you to shrink Windows first); the disk is in use |
| `whole disk` | destroys everything on the disk and creates the two partitions | the disk is classified `windows`, `other-os` or `unknown` and you did not type exactly `no windows, wipe`; the disk is in use. A wrong typed phrase or disk name aborts with nothing changed |

An `empty` disk needs no phrase, only the final disk-name confirmation. The installer never deletes or recreates the `Windows Boot Manager` firmware entry; it only reorders the boot order.

### What it does, step by step

1. Refuses to run unless it is the live installer, root, and booted in UEFI mode (a `--dry-run` only warns).
2. Clones `main` and evaluates `nixosConfigurations.<host>[-2]` once to learn user, uid, LUKS, lanzaboote, key paths and the Attic cache.
3. Secure Boot gate (lanzaboote hosts), then disk selection, mode checks, the plan and the typed confirmation.
4. Finds and decrypts the bundle into a tmpfs work dir (a bundle for another host aborts here, before any partitioning), derives the age identity from the host key and decrypts `tailscale_key` and `attic-push-token` from the common sops file.
5. Starts `tailscaled` on the live system and joins the tailnet as `<host>-2` (the key is read from a file, never passed on a command line).
6. Partitions the disk, formats (LUKS2 on the laptop), creates the btrfs subvolumes and mounts everything under `/mnt`.
7. Places the host key in `/mnt/persist/etc/ssh` and the user age key in `/mnt/home/<user>/.config/sops/age/keys.txt`.
8. Creates the Secure Boot keys with `sbctl` in `/mnt/persist/var/lib/sbctl` (needed even without Setup Mode because lanzaboote signs during the install).
9. Runs `nixos-install` against the local clone as flake `#<host>-2` with no root password, adding the Attic cache as substituter when it answers (otherwise it warns and builds what is missing).
10. If the firmware is in Setup Mode: `sbctl enroll-keys --microsoft`.
11. Copies the live Tailscale state to `/mnt/persist/var/lib/tailscale` (only when the join worked), so the machine keeps its node identity.
12. Creates the firmware entry `NixOS (<host>-2)` and puts it first in the boot order.
13. Copies the repository to `~/nix` of the target user, sets `origin` to the public URL (`https://github.com/nicolkrit999/nix.git`) and runs `git fetch --unshallow` (a failure is only a warning; the clone stays shallow).
14. Shreds the tmpfs work dir and prints the final checklist.

Then continue with the [post-install checklist](./clone-post-install.md).

## Fallback without the custom ISO

On any stock NixOS minimal ISO with network (and the bundle on a stick):

```bash
sudo nix --extra-experimental-features 'nix-command flakes' run github:nicolkrit999/nix#install
```

It runs the same installer (it must be started as root; the wrapper does not escalate itself) and clones `main` for the config. Differences: the stock kernel may not support brand-new hardware, `nixos-install` fetches locked flake inputs from GitHub without a token (rate limits are possible), and the script comes from the flake ref while the config comes from a fresh clone of `main`, so keep them in step by merging to `main` first.

## Known unverified items

Covered by automated checks (sparse image files, fake tools, flake-output invariants; see the clone installer row in [tests overview](../usage/tests/tests-overview.md)), but not yet confirmed on real machines:

- **Real firmware enrollment.** `sbctl create-keys` and `enroll-keys` run with a temporary `--config` file that points to the target's `pkiBundle`; sbctl's landlock sandbox with a custom path has not been seen on real firmware or the real ISO. If it fails, the manual route is the enrollment phase of [lanzaboote](./lanzaboote.md) after the first boot.
- **New-hardware kernel support.** The ISO uses the laptop's kernel; the generic hardware layer lists broad initrd modules and does no hardware detection. A machine needing a driver outside that list may not boot the installed system.
- **Ventoy exFAT stick scan.** The installer mounts removable partitions read-only and looks for `*.age` two levels deep; only fakes have exercised this. If no bundle is found it asks for the path (`mount` the partition by hand first).
- **`tailscale up --auth-key=file:`** (path-to-file key syntax) needs a recent tailscale and was only tested against a fake.
- **Booting the ISO itself** through Ventoy, the ISO size, and Wi-Fi on real hardware.
- **Version skew in the fallback**: script from the flake ref, config from `main`.
- **The `systemctl reboot --firmware-setup` hint** printed by the gate is generic; some boards need the vendor key at power-on.
