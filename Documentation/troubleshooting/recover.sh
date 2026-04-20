#!/usr/bin/env bash
# NixOS Automated Chroot & Recovery Script

# --- CONFIGURATION ---
HOSTNAME="nixos-desktop"
FLAKE_DIR="/home/krit/nix"
ROOT_LABEL="nixos"
BOOT_LABEL="boot"
# ---------------------

# Ensure the script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (sudo ./recover.sh)"
  exit 1
fi

echo "🚀 Starting automated NixOS recovery sequence..."

# 1. Unmount everything first just in case of a previous failed run
echo "🧹 Cleaning up any existing mounts..."
umount -R /mnt 2>/dev/null || true

# 2. Mount the Root Subvolume (@)
echo "📁 Mounting root subvolume..."
mount -o subvol=@ /dev/disk/by-label/$ROOT_LABEL /mnt

# 3. Create mount points
echo "📂 Creating subvolume directories..."
mkdir -p /mnt/{home,nix,var/log,persist,boot}

# 4. Mount the remaining Btrfs subvolumes
echo "🔗 Mounting remaining subvolumes..."
mount -o subvol=@home /dev/disk/by-label/$ROOT_LABEL /mnt/home
mount -o subvol=@nix /dev/disk/by-label/$ROOT_LABEL /mnt/nix
mount -o subvol=@log /dev/disk/by-label/$ROOT_LABEL /mnt/var/log
mount -o subvol=@persist /dev/disk/by-label/$ROOT_LABEL /mnt/persist

# 5. Mount the Boot/EFI partition
echo "🥾 Mounting boot partition..."
mount /dev/disk/by-label/$BOOT_LABEL /mnt/boot

echo "✅ Filesystem mounted successfully!"

# 6. Automate DNS Fix, Binfmt Fix, and Git inside the chroot
echo "🔧 Prepping the chroot environment..."
nixos-enter -c "
  echo '-> Forcing public DNS (1.1.1.1)...'
  rm -f /etc/resolv.conf
  echo 'nameserver 1.1.1.1' > /etc/resolv.conf
  
  echo '-> Creating binfmt directory to prevent QEMU errors...'
  mkdir -p /run/binfmt
  
  echo '-> Stashing changes and checking out main branch...'
  cd $FLAKE_DIR
  git stash -u
  git checkout main
"

# 7. Print the final manual instructions
echo ""
echo "=================================================================="
echo "🚨 SYSTEM READY FOR RECOVERY 🚨"
echo "=================================================================="
echo "You are about to be dropped into the NixOS chroot."
echo "To reinstall the bootloader and fix your system, run this exact command:"
echo ""
echo "    cd $FLAKE_DIR"
echo "    NIXOS_INSTALL_BOOTLOADER=1 nixos-rebuild boot --flake .#$HOSTNAME"
echo ""
echo "When the rebuild finishes successfully:"
echo "    1. Type 'exit' to leave the chroot."
echo "    2. Type 'reboot' to restart."
echo "    3. Remove your Live USB."
echo "=================================================================="
echo ""

# 8. Drop the user into the chroot
nixos-enter
