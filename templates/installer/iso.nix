{ lib, pkgs, modulesPath, installerPkgs, laptopKernelPackages, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  nixpkgs.hostPlatform = "x86_64-linux";
  nixpkgs.config.allowUnfree = true;

  boot.kernelPackages = laptopKernelPackages;
  boot.supportedFilesystems.zfs = lib.mkForce false;

  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = installerPkgs.tools ++ [
    installerPkgs.clone-install
    installerPkgs.installer
    installerPkgs.make-bundle
    pkgs.networkmanager
  ];

  image.baseName = lib.mkForce "clone-installer-x86_64-linux";

  services.getty.helpLine = lib.mkForce ''

    Reinstall a host from the latest main:  clone-install   (run it as the nixos user, it asks for sudo)
    Wi-Fi: nmtui     Dry run: clone-install --dry-run
  '';
}
