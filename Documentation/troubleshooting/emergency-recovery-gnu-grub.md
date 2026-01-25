# 🚨 NixOS Emergency Recovery & Maintenance Manual

## 1. Live USB Recovery (The "Deep" Fix)

Use this if you encounter the **"GNU GRUB minimal bash-like"** screen or a total boot failure.

### A. Identify Your Hardware

Run `lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT,UUID` to confirm partition names. Search for this pattern:

- **`nvme3n1p1` (1GB)**: EFI/Boot partition (FAT32).
- **`nvme3n1p2` (1.8TB)**: Main Btrfs partition containing system subvolumes.

### B. The Mounting Sequence

You must mount subvolumes in this specific order to rebuild the system "map":

```bash
# 1. Mount the Root subvolume (@)
mount -o subvol=@ /dev/nvme3n1p2 /mnt

# 2. Mount Nix Store and Home (@nix, @home)
mkdir -p /mnt/nix /mnt/home /mnt/boot
mount -o subvol=@nix /dev/nvme3n1p2 /mnt/nix
mount -o subvol=@home /dev/nvme3n1p2 /mnt/home

# 3. Mount the physical EFI partition
mount /dev/nvme3n1p1 /mnt/boot

```

### C. Reinstalling from the Host Config

```bash
cd /mnt/home/<username>/nixOS
sudo nixos-install --root /mnt --flake .#hostname --option tarball-ttl 0

```

---

## 2. No-USB Recovery (The "Time Machine" Fix)

Use this if the system crashes but you can still reach the GRUB bootloader.

### A. Accessing Generations

1. On the GRUB screen, select **"NixOS - All configurations"**.
2. Select an older version from a date/time when the system was working.
3. Boot into it. This uses a "known good" state of your software without touching the broken version on disk.

### B. Hardening Your Bootloader

Add this to your `boot.nix` to prevent the menu from corrupting or becoming too large:

```nix
boot.loader.grub.configurationLimit = 20; # Always keep 20 versions available

```

---

## 3. Post-Recovery Safety Checklist

- **Safe Logout**: If the screen hangs at a blinking `_`, do not force-reboot. Press `Ctrl+Alt+F3`, login, and type `sudo reboot` to safely unmount Btrfs.
- **Testing**: Always use `sudo nixos-rebuild test --flake .#nixos-desktop` for experimental changes. If it fails, a simple reboot returns you to safety because `test` does not update the GRUB menu.

Would you like me to explain how to "pin" your current working recovery state so it never gets deleted by garbage collection?
