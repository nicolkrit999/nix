{ config, pkgs, ... }:

{
  # 1. Required Kernel Module for virtual keypresses
  boot.kernelModules = [ "uinput" ];

  # 2. Install the package
  environment.systemPackages = [ pkgs.logiops ];

  # 3. Create the configuration file at /etc/logid.cfg
  environment.etc."logid.cfg".text = ''
    devices: (
      {
        name: "MX Master 3S";
        smartshift: {
          on: true;
          threshold: 20;
        };
        hiresscroll: {
          hires: true;
          invert: false;
          target: false;
        };
        dpi: 1200;

        thumbwheel: {
          divert: true;
          invert: false;
          left: {
            mode: "OnInterval";
            interval: 1;
            action: {
              type: "Keypress";
              keys: ["KEY_VOLUMEDOWN"];
            };
          };
          right: {
            mode: "OnInterval";
            interval: 1;
            action: {
              type: "Keypress";
              keys: ["KEY_VOLUMEUP"];
            };
          };
        };

        buttons: (
          {
            # Forward Button -> Copy
            cid: 0x53;
            action: {
              type: "Keypress";
              keys: ["KEY_LEFTCTRL", "KEY_C"];
            };
          },
          {
            # Back Button -> Paste
            cid: 0x56;
            action: {
              type: "Keypress";
              keys: ["KEY_LEFTCTRL", "KEY_V"];
            };
          },
          {
            # Gesture Button -> Meta/Super
            cid: 0xc3;
            action: {
              type: "Keypress";
              keys: ["KEY_LEFTMETA"];
            };
          }
        );
      }
    );
  '';

  # 4. Define the Systemd Service manually
  systemd.services.logid = {
    description = "Logitech Configuration Daemon";
    wantedBy = [ "multi-user.target" ];

    # Ensure it restarts if it crashes or the device sleeps
    serviceConfig = {
      ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid.cfg";
      Restart = "always";
      RestartSec = "3s";
    };
  };
}
