{ config
, lib
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=4G" "mode=755" ];
  };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/5eb47d8e-8b29-4fe5-ba2b-13216f46513c";
    fsType = "btrfs";
    options = [ "subvol=@persist" "compress=zstd" "noatime" ];
    neededForBoot = true;
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/5eb47d8e-8b29-4fe5-ba2b-13216f46513c";
    fsType = "btrfs";
    options = [ "subvol=@home" ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/5eb47d8e-8b29-4fe5-ba2b-13216f46513c";
    fsType = "btrfs";
    options = [ "subvol=@nix" ];
  };

  fileSystems."/var/log" = {
    device = "/dev/disk/by-uuid/5eb47d8e-8b29-4fe5-ba2b-13216f46513c";
    fsType = "btrfs";
    options = [ "subvol=@log" ];
    neededForBoot = true;
  };

  fileSystems."/.snapshots" = {
    device = "/dev/disk/by-uuid/5eb47d8e-8b29-4fe5-ba2b-13216f46513c";
    fsType = "btrfs";
    options = [ "subvol=@snapshots" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2375-F650";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
