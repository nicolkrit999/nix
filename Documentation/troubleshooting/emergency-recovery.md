# 🚨 NixOS Emergency Recovery & Maintenance Manual

## 1. Live USB Recovery (The "Deep" Fix)

Use this if you encounter the **"GNU GRUB minimal bash-like"** screen, or no
boot menu appears at all (no GRUB, no systemd-boot). If the boot menu still
shows (GRUB, or the systemd-boot menu of a lanzaboote host), use section 2
instead.

Which bootloader a host uses: **lanzaboote** (signed systemd-boot) when
`myconfig.services.lanzaboote.enable` is true for it, GRUB otherwise. Section B
is the GRUB/generic manual fallback, section C the lanzaboote one.

### A. Automated: `recover.sh` (recommended)

> Step-by-step guide for the whole process (making the USB, every prompt,
> what to do after): [README.md](./README.md).

> `recover.sh` has only been tested against fixture trees, never on a real
> live ISO. On a first real run start with `--shell` (mounts and opens a
> chroot, rebuilds nothing); sections B and C are the manual equivalent.

Boot a NixOS live USB in UEFI mode, then:

```bash
nix-shell -p git                      # if git is missing
git clone https://github.com/nicolkrit999/nix && cd nix
./Documentation/troubleshooting/recover.sh
```

It detects everything from the disk itself (any host, encrypted or not,
tmpfs root or not, dual boot or not, GRUB or lanzaboote): it offers `nmtui` if
there's no internet, asks for the LUKS passphrase if there is an encrypted
partition, finds the NixOS install, mounts it from the system's own fstab,
stashes uncommitted changes in the on-disk repo and fast-forwards `main`,
decides the bootloader (flake first, disk files as fallback), then runs
`nixos-rebuild boot --install-bootloader` in a chroot, finishes with the
bootloader-specific check (GRUB: stale copies; lanzaboote: `sbctl verify` and
the firmware entry), unmounts and offers to reboot. See `--help` for the
options (hostname override, `--keep-changes`, `--shell`, `--skip-mount`;
`--grub-only` is for GRUB hosts).

**lanzaboote host: switch Secure Boot OFF in the BIOS before booting
the live USB** (a stock ISO is not signed with your keys) and back ON
afterwards. The script checks the signing key first and never creates keys on
its own.

### B. Manual fallback (GRUB, and the mounting part for every host)

Layout of an impermanence host (see the host's `hardware-configuration.nix`):
`/` is a **tmpfs** (there is no `@` root subvolume) and everything persistent
lives in Btrfs subvolumes. On a LUKS host the Btrfs sits inside LUKS.

```bash
lsblk -f                                         # find the partitions
cryptsetup open /dev/<luks-partition> cryptroot  # LUKS hosts only: asks the passphrase
BTRFS=/dev/mapper/cryptroot                      # no LUKS: the Btrfs partition itself

mount -t tmpfs -o mode=755 none /mnt
mkdir -p /mnt/{nix,home,persist,var/log,boot,etc}
mount -o subvol=@nix     $BTRFS /mnt/nix
mount -o subvol=@home    $BTRFS /mnt/home
mount -o subvol=@persist $BTRFS /mnt/persist
mount -o subvol=@log     $BTRFS /mnt/var/log
mount /dev/<efi-partition> /mnt/boot
touch /mnt/etc/NIXOS                             # nixos-enter refuses an empty root without it

nixos-enter --root /mnt
# inside the chroot:
mkdir -p /run/binfmt                             # hosts with binfmt emulation: its sandbox path must exist
cd /home/<user>/nix
nixos-rebuild boot --install-bootloader --flake .#<hostname>
# add `--option sandbox false` if the build fails with sandbox/namespace errors
exit
umount -R /mnt && reboot
```

For a lanzaboote host the same mount steps apply, but read section C before
running the rebuild: the signing keys must be reachable first.

### C. Manual fallback for a lanzaboote host

Use this when `recover.sh` cannot be used. Background and the key/Secure Boot
procedures: [lanzaboote.md](../usage/secure-boot/lanzaboote.md).

1. **BIOS: switch Secure Boot OFF** (admin password; keep the enrolled keys,
   do not reset them), then boot the live ISO in UEFI mode.
2. Unlock and mount exactly as in section B. `/persist` must be mounted: the
   signing keys live there and nothing else (no bind mount) is needed.
3. Check the key directory. It is `config.boot.lanzaboote.pkiBundle`, which
   is `/persist/var/lib/sbctl` on an impermanence host; a host without
   impermanence normally uses `/var/lib/sbctl`. The installed system's
   `/etc/sbctl/sbctl.conf` names the exact `keydir`/`guid` pair.
   ```bash
   ls -l /mnt/persist/var/lib/sbctl /mnt/persist/var/lib/sbctl/keys/db
   # expected: GUID and keys/{PK,KEK,db}/*.key + *.pem, root only
   ```
   If it is missing, restore the encrypted key archive from the password
   manager: `tar -xpf <archive> -C /mnt/persist/var/lib/sbctl`. Only if the
   old keys are really lost: `sbctl create-keys` in the chroot creates
   **new** ones, which do **not** match the firmware db, so Secure Boot must
   stay off and the key enrollment and Secure Boot steps of
   [Adding lanzaboote](../installation/lanzaboote.md) (phases 2 and 3) must be repeated.
4. Check the boot partition has room (about 160 MB per kernel + initrd set):
   `df -h /mnt/boot`. If the ESP is corrupt, `fsck.fat -a /dev/<efi-partition>`
   (unmounted), and remove only the files lanzaboote owns:
   `rm -fr /mnt/boot/EFI/Linux/nixos-generation-*.efi /mnt/boot/EFI/nixos`.
5. Rebuild and reinstall the signed boot files:
   ```bash
   nixos-enter --root /mnt
   mkdir -p /run/binfmt
   cd /home/<user>/nix
   nixos-rebuild boot --install-bootloader --flake .#<hostname>
   # add `--option sandbox false` if the build fails with sandbox/namespace errors
   sbctl verify          # see below
   exit
   ```
   `nixos-rebuild boot --install-bootloader` is the lanzaboote install hook
   (`switch`/`boot` only, never `test`). It writes no EFI variables and
   overwrites `EFI/BOOT/BOOTX64.EFI` with the signed systemd-boot.
6. `sbctl verify`: `EFI/Linux/nixos-*.efi`, `EFI/BOOT/BOOTX64.EFI` and
   `EFI/systemd/systemd-bootx64.efi` **must** be signed. A red cross for
   `EFI/nixos/kernel-*.efi` is expected (the signed stub checks it by hash),
   and so are red crosses for leftover GRUB files (`EFI/NixOS-boot/…`,
   `/boot/grub/…`, `/boot/kernels/…`) on a host migrated from GRUB that has
   not cleaned them up yet.
7. If the firmware lost its NixOS entry (`efibootmgr -v` shows none that
   points at the boot partition's PARTUUID), create one from the live ISO,
   with disk and partition number of the mounted `/boot` device:
   ```bash
   findmnt -no SOURCE /mnt/boot                       # /dev/<disk><n>
   efibootmgr -c -d /dev/<disk> -p <n> -l '\EFI\BOOT\BOOTX64.EFI' -L 'NixOS lanzaboote'
   ```
8. `umount -R /mnt`, close LUKS (`cryptsetup close cryptroot`), reboot, switch
   **Secure Boot back ON** in the BIOS. On a LUKS + TPM host the disk keeps
   unlocking by itself only if PCR 7 is unchanged; otherwise type the
   passphrase once and re-seal:
   `sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=7 /dev/<luks-partition>`.

---

## 2. No-USB Recovery (The "Time Machine" Fix)

Use this if the system crashes but you can still reach the boot menu.

### A. Accessing Generations

GRUB host:

1. On the GRUB screen, select **"NixOS - All configurations"**.
2. Select an older version from a date/time when the system was working.
3. Boot into it. This uses a "known good" state of your software without touching the broken version on disk.

lanzaboote host: the systemd-boot menu lists the generations
directly; pick an older one (the stubs are signed, so this works with Secure
Boot ON). If the firmware refuses the loader itself, switch Secure Boot off in
the BIOS first.

### B. Hardening Your Bootloader

Already set to keep the menu from growing too large. GRUB hosts, in
`modules/nixos/toplevel/boot.nix`:

```nix
boot.loader.grub.configurationLimit = 10;
```

lanzaboote hosts: `myconfig.services.lanzaboote.configurationLimit` (every
generation also keeps its specialisations on the ESP).

---

## 3. Post-Recovery Safety Checklist

- **Safe Logout**: If the screen hangs at a blinking `_`, do not force-reboot. Press `Ctrl+Alt+F3`, login, and type `sudo reboot` to safely unmount Btrfs.
- **Testing**: Always use `sudo nixos-rebuild test --flake .#<host>` for experimental changes. If it fails, a simple reboot returns you to safety because `test` does not touch the bootloader (neither the GRUB menu nor the lanzaboote boot files).

