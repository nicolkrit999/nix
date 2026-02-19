{ delib, pkgs, ... }:
delib.module {
  name = "krit-logitech";
  options.krit.hardware.logitech.enable = delib.boolOption true;

  nixos.ifEnabled =
    { cfg, ... }:
    {
      imports = [
        ./superlight.nix
        ./mx-master.nix
      ];

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
