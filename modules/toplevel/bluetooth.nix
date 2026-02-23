{ delib, pkgs, ... }:
delib.module {
  name = "bluetooth";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;

      settings = {
        Policy = {
          AutoEnable = "true"; # Enable on boot
        };
      };
    };

    services.blueman.enable = true;
  };
}
