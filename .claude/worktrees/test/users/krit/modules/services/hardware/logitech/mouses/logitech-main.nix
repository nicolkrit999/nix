{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech";
  options.krit.services.logitech = with delib; {
    enable = boolOption false;
    logidDeviceBlocks = listOfOption str [ ];
  };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      hardware.logitech.wireless.enable = true;
      hardware.logitech.wireless.enableGraphical = true;

      environment.systemPackages = with pkgs; [
        keyd
        logiops
        libinput
        evtest
      ];

      services.keyd.enable = true;
      boot.kernelModules = [
        "uinput"
        "hid-logitech-hidpp"
      ];

      environment.etc."logid.cfg".text = ''
        devices: (
          ${builtins.concatStringsSep ",\n" cfg.logidDeviceBlocks}
        );
      '';

      systemd.services.logid = {
        description = "Logitech Configuration Daemon";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
          Restart = "always";
          RestartSec = "3s";
        };
      };
    };
}
