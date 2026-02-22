{ delib, pkgs, ... }:
delib.module {
  name = "bluetooth";
  options.bluetooth = with delib; {
    enable = boolOption false;
  };

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

    # TODO: check if really needed
    systemd.services.bluetooth-unblock = {
      description = "Unblock Bluetooth on boot";
      after = [ "bluetooth.service" ];
      requires = [ "bluetooth.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.util-linux}/bin/rfkill unblock bluetooth";
      };
    };
  };
}
