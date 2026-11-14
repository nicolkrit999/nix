{ delib, pkgs, inputs, ... }:
let
  # Pinned to gen 1483's nixpkgs (zen 7.2.15): zen 7.3.4-zen1 hangs at boot (nixpkgs#587387).
  # Remove (use pkgs.linuxPackages_zen, drop the nixpkgs-kernel input) once the locked
  # nixpkgs has zen 7.3.4-zen2 or newer (commit 9ca0e988) and a boot test passes.
  kernelPkgs = import inputs.nixpkgs-kernel {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
in
delib.module {
  name = "kernel";
  nixos.always = { myconfig, ... }: {
    boot.kernelPackages =
      (
        if myconfig.constants.hostname == "nixos-desktop" then
          kernelPkgs.linuxPackages_zen
        else if myconfig.constants.hostname == "nixos-laptop" then
          pkgs.linuxKernel.packages.linux_testing
        else
          pkgs.linuxPackages
      ).extend
        (
          _kfinal: kprev: {
            v4l2loopback = kprev.v4l2loopback.overrideAttrs (old: {
              env = (old.env or { }) // {
                DEPMOD = "true";
              };
            });
          }
        );
  };
}
