{ delib, pkgs, ... }:
delib.module {
  name = "kernel";
  nixos.always = {
    # Use Zen kernel on x86 (Desktop), but standard Linux on ARM (VM/Pi/Apple)
    boot.kernelPackages =
      if pkgs.stdenv.hostPlatform.system == "x86_64-linux" then
        pkgs.linuxPackages_zen
      else
        pkgs.linuxPackages_latest;
  };
}
