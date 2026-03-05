{ config
, lib
, pkgs
, modulesPath
, ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # 🛠️ Boot & Kernel Modules
  # These are necessary for the hardware to "see" the disk before mounting
  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # 🖥️ ARM ARCHITECTURE
  # mkDefault allows this host to coexist with your x86_64 desktop in flake checks
  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
