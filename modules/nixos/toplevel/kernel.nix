{ delib, pkgs, ... }:
delib.module {
  name = "kernel";
  nixos.always = { myconfig, ... }: {
    boot.kernelPackages =
      if myconfig.constants.hostname == "nixos-laptop" then
        pkgs.linuxPackages_testing
      else if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
        pkgs.linuxPackages_zen
      else
        pkgs.linuxPackages_latest;
  };
}
