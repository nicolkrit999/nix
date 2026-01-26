{ pkgs, lib, ... }:
{
  boot.loader = {
    timeout = 30; # Increase bootloader timeout to 30 seconds
    efi.canTouchEfiVariables = true;

    # Forces off systemd-boot
    systemd-boot.enable = lib.mkForce false;

    grub = {
      enable = lib.mkForce true;
      device = "nodev";
      efiSupport = true;
      useOSProber = true;
      gfxmodeEfi = "1920x1080";
      # configurationLimit = 20; # Example of setting a configuration limit that show up while booting
      extraGrubInstallArgs = [ "--bootloader-id=nixos" ];

      extraEntries = ''
        menuentry "UEFI Firmware Settings" {
          fwsetup
        }
      '';
    };
  };
}
