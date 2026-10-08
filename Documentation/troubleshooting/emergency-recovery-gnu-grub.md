# 🚨 NixOS Emergency Recovery & Maintenance Manual

## 1. Live USB Recovery (The "Deep" Fix)

Use this if you encounter the **"GNU GRUB minimal bash-like"** screen or GRUB
doesn't appear at all. If GRUB still shows its menu, use section 2 instead.

### A. Automated: `recover.sh` (recommended)

Boot a NixOS live USB in UEFI mode, then:

```bash
nix-shell -p git                      # if git is missing
git clone https://github.com/nicolkrit999/nix && cd nix
./Documentation/troubleshooting/recover.sh
```

It detects everything from the disk itself (any host, encrypted or not,
tmpfs root or not, dual boot or not): it offers `nmtui` if there's no
internet, asks for the LUKS passphrase if there is an encrypted partition,
finds the NixOS install, mounts it from the system's own fstab, stashes
uncommitted changes in the on-disk repo and fast-forwards `main`, then runs
`nixos-rebuild boot --install-bootloader` in a chroot, unmounts and offers to
reboot. See `--help` for the options (hostname override, `--keep-changes`,
`--shell`, `--skip-mount`).

### B. Manual fallback

Current layout of `nixos-desktop` / `nixos-laptop` (see each host's
`hardware-configuration.nix`): `/` is a **tmpfs** (impermanence, there is no
`@` root subvolume), everything persistent lives in Btrfs subvolumes, and on
the laptop the Btrfs sits inside LUKS.

```bash
lsblk -f                                         # find the partitions
cryptsetup open /dev/<luks-partition> cryptroot  # laptop only: asks the passphrase
BTRFS=/dev/mapper/cryptroot                      # desktop: the Btrfs partition itself

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
mkdir -p /run/binfmt                             # desktop: its binfmt sandbox path must exist
cd /home/krit/nix
nixos-rebuild boot --install-bootloader --flake .#<hostname>
# add `--option sandbox false` if the build fails with sandbox/namespace errors
exit
umount -R /mnt && reboot
```

---

## 2. No-USB Recovery (The "Time Machine" Fix)

Use this if the system crashes but you can still reach the GRUB bootloader.

### A. Accessing Generations

1. On the GRUB screen, select **"NixOS - All configurations"**.
2. Select an older version from a date/time when the system was working.
3. Boot into it. This uses a "known good" state of your software without touching the broken version on disk.

### B. Hardening Your Bootloader

Already set in `modules/nixos/toplevel/boot.nix`, to keep the menu from growing too large:

```nix
boot.loader.grub.configurationLimit = 10;

```

---

## 3. Post-Recovery Safety Checklist

- **Safe Logout**: If the screen hangs at a blinking `_`, do not force-reboot. Press `Ctrl+Alt+F3`, login, and type `sudo reboot` to safely unmount Btrfs.
- **Testing**: Always use `sudo nixos-rebuild test --flake .#nixos-desktop` for experimental changes. If it fails, a simple reboot returns you to safety because `test` does not update the GRUB menu.

