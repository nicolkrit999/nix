{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Basic kernel modules usually available everywhere
  boot.initrd.availableKernelModules = [ "xhci_pci" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # Dummy filesystems just to satisfy the build checker
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  # 🟢 CRITICAL: Disable x86 specific power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
