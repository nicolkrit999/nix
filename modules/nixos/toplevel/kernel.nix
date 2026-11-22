{ delib, pkgs, ... }:
delib.module {
  name = "kernel";
  nixos.always = { myconfig, ... }: {
    boot.kernelPackages =
      if myconfig.constants.hostname == "nixos-desktop" then
        pkgs.linuxPackages_zen
      else if myconfig.constants.hostname == "nixos-laptop" then
        pkgs.linuxKernel.packages.linux_testing
      else
        pkgs.linuxPackages;
  };
}
