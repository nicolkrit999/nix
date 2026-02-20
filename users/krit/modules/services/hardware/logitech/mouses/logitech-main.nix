{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech.mouses";
  options.krit.services.logitech.mouses = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {

      environment.systemPackages = with pkgs; [
        keyd # for Superlight
        logiops # for MX Master
        libinput # for debugging
        evtest # for hardware testing
      ];

      services.keyd.enable = true;
      boot.kernelModules = [
        "uinput"
        "hid-logitech-hidpp"
      ];

      # Service Definition
      systemd.services.logid = {
        description = "Logitech Configuration Daemon";
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
          Restart = "always";
          RestartSec = "3s";
        };
      };

      # Auto-Restart logid ONLY when MX Master connects
      services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", RUN+="${pkgs.systemd}/bin/systemctl restart logid.service"
      '';
    };
}
