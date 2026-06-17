{ delib, pkgs, ... }:
delib.module {
  name = "kernel";
  nixos.always = { myconfig, ... }: {
    boot.kernelPackages =
      if myconfig.constants.hostname == "nixos-desktop" then
        pkgs.linuxPackages_zen
      else if myconfig.constants.hostname == "nixos-laptop" || myconfig.constants.hostname == "Krits-MacBook-Pro" then
        pkgs.linuxPackages_latest
      else
        pkgs.linuxPackages;
  };
}
