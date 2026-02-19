{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "system.boot";

  nixos.always = {
    boot.loader = {
      timeout = 30;
      efi.canTouchEfiVariables = true;

      systemd-boot.enable = lib.mkForce false;

      grub = {
        enable = lib.mkForce true;
        device = "nodev";
        efiSupport = true;
        useOSProber = true;
        extraGrubInstallArgs = [ "--bootloader-id=nixos" ];

        extraEntries = ''
          menuentry "UEFI Firmware Settings" {
            fwsetup
          }
        '';
      };
    };
  };
}
