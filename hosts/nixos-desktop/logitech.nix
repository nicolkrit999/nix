{ config, pkgs, ... }:

{
  # 1. Required Kernel Module
  boot.kernelModules = [ "uinput" ];

  # 2. Install the package
  environment.systemPackages = [ pkgs.logiops ];

  # 3. Create the configuration file
  # NOTICE: We use "MX Master 3S" here because that is what logid sees.
  environment.etc."logid.cfg".text = ''
    devices: (
      {
        name: "MX Master 3S";
        smartshift: { on: true; threshold: 20; };
        hiresscroll: { hires: true; invert: false; target: false; };
        dpi: 1200;
        thumbwheel: {
          divert: true;
          invert: false;
          left: { mode: "OnInterval"; interval: 1; action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
          right: { mode: "OnInterval"; interval: 1; action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
        };
        buttons: (
          { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
          { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; },
          { cid: 0xc3; action: { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; }
        );
      }
    );
  '';

  # 4. THE FIX: The Udev rule uses "Logitech MX Master 3S" because that is what the Kernel sees.
  # We use ATTR{name} to match the specific input device attribute.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Logitech MX Master 3S", RUN+="${pkgs.systemd}/bin/systemctl restart logid.service"
  '';

  # 5. Define the Service
  systemd.services.logid = {
    description = "Logitech Configuration Daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
