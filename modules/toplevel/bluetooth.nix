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

      # Force the controller to be powered on via BlueZ settings
      settings = {
        Policy = {
          AutoEnable = "true";
        };
      };
    };

    services.blueman.enable = true;

    # Clear rfkill block states that might persist across reboots
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
