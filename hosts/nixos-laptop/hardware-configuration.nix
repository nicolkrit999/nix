{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  # Essential modules for ARM and NVMe/USB boot
  boot.initrd.availableKernelModules = [
    "nvme"
    "usb_storage"
    "xhci_pci"
    "usbhid"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
