{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "bluetooth";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      autoEnableOnBoot = boolOption true;
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = cfg.autoEnableOnBoot;
      };

      services.blueman.enable = true;

      systemd.services.bluetooth-autoenable = lib.mkIf cfg.autoEnableOnBoot {
        description = "Unblock and power on Bluetooth at boot";
        wantedBy = [ "multi-user.target" ];
        after = [
          "bluetooth.service"
          "systemd-rfkill.service"
        ];
        requires = [ "bluetooth.service" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        path = [
          pkgs.util-linux
          pkgs.bluez
          pkgs.coreutils
        ];
        script = ''
          rfkill unblock bluetooth
          sleep 2
          bluetoothctl power on
        '';
      };
    };
}
