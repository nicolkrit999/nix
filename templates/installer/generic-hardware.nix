{ luks ? false }:
{ config, lib, ... }:
let
  layout = import ./layout.nix;
  btrfsDevice =
    if luks then
      "/dev/mapper/${layout.luksMapperName}"
    else
      "/dev/disk/by-label/${layout.btrfsLabel}";
  zstdOpts = [ "compress=zstd" "noatime" ];
  btrfsFs = subvol: opts: extra: {
    device = btrfsDevice;
    fsType = "btrfs";
    options = [ "subvol=${subvol}" ] ++ opts;
  } // extra;
  allOpts = if luks then zstdOpts else [ ];
in
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "ehci_pci"
    "usb_storage"
    "uas"
    "usbhid"
    "sd_mod"
    "sdhci_pci"
    "rtsx_pci_sdmmc"
    "thunderbolt"
    "vmd"
    "virtio_pci"
    "virtio_blk"
    "virtio_scsi"
  ];

  # kvm-amd / kvm-intel carry CPU-feature (svm / vmx) aliases, so udev loads
  # the matching one; listing both in boot.kernelModules would fail the
  # modules-load unit on the CPU vendor that does not match.

  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems = {
    "/" = {
      device = if luks then "tmpfs" else "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=${layout.rootTmpfsSize}" "mode=755" ];
    };
    "/persist" = btrfsFs layout.subvolumes.persist zstdOpts { neededForBoot = true; };
    "/home" = btrfsFs layout.subvolumes.home allOpts { };
    "/nix" = btrfsFs layout.subvolumes.nix allOpts { };
    "/var/log" = btrfsFs layout.subvolumes.log allOpts { neededForBoot = true; };
    "/boot" = {
      device = "/dev/disk/by-label/${layout.espLabel}";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  boot.initrd.luks.devices = lib.mkIf luks {
    ${layout.luksMapperName}.device = "/dev/disk/by-partlabel/${layout.luksPartLabel}";
  };
}
