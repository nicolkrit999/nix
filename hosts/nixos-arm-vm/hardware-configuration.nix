{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

  # 1. Hardware Drivers
  boot.initrd.availableKernelModules =
    [ "xhci_pci" "virtio_pci" "usbhid" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # 2. File Systems (Matching your Disko Layout)

  # Root Partition (Btrfs Subvolume @)
  fileSystems."/" = {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [ "subvol=@" "compress=zstd" "noatime" ];
  };

  # Boot Partition (FAT32)
  fileSystems."/boot" = {
    device = "/dev/vda1";
    fsType = "vfat";
  };

  # Home Partition (Btrfs Subvolume @home)
  fileSystems."/home" = {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [ "subvol=@home" "compress=zstd" "noatime" ];
  };

  # Nix Store (Btrfs Subvolume @nix)
  fileSystems."/nix" = {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [ "subvol=@nix" "compress=zstd" "noatime" ];
  };

  # Logs (Btrfs Subvolume @log)
  fileSystems."/var/log" = {
    device = "/dev/vda2";
    fsType = "btrfs";
    options = [ "subvol=@log" "compress=zstd" "noatime" ];
  };
}
