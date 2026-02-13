{ pkgs, ... }:

let
  # Import MX Master config string
  mxConfig = import ./mx-master.nix;
in
{
  # Superlight (using keyd)
  imports = [ ./superlight.nix ];

  # -----------------------------------------------------
  # 🖱️ MX MASTER CONFIGURATION (via logid)
  # -----------------------------------------------------
  boot.kernelModules = [
    "uinput"
    "hid-logitech-hidpp"
  ];
  environment.systemPackages = [ pkgs.logiops ];

  # Generate logid.cfg ONLY for MX Master
  environment.etc."logid.cfg".text = ''
    devices: (
      {
        name: "Wireless Mouse MX Master 3S";
        ${mxConfig.sharedConfig}
      },
      {
        name: "MX Master 3S";
        ${mxConfig.sharedConfig}
      }
    );
  '';

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
}
