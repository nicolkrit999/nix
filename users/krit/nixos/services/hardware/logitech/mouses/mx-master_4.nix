{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech.mouses.mx-master-4";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      logiops
      libinput
      evtest
    ];

    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/control}="on"
    '';

    environment.etc."logid-mx4.cfg".text = ''
      devices: (
        {
          name: "MX Master 4";
          productId: 0xb042;
          smartshift: { on: true; threshold: 13; };
          dpi: 1200;
          hiresscroll: { enabled: true; invert: false; target: false; };
          scrollwheel: { hires: true; invert: false; target: false; pixels_per_step: 2.0; };

          thumbwheel: {
            divert: true;
            invert: false;
            left: { mode: "OnInterval"; interval: 2; action = { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
            right: { mode: "OnInterval"; interval: 2; action = { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
          };

          buttons: (
            { cid: 0x53; action = { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
            { cid: 0x56; action = { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; },
            { cid: 0xc3; action = { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_Z"]; }; },

            {
              cid: 0x1a0;
              action = {
                type: "Gestures";
                gestures: (
                  { direction: "None";  mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_PLAYPAUSE"]; }; },
                  { direction: "Left";  mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_F13"]; }; },
                  { direction: "Right"; mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_F14"]; }; },
                  { direction: "Up";    mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_F15"]; }; },
                  { direction: "Down";  mode: "OnRelease"; action = { type: "Keypress"; keys: ["KEY_F16"]; }; }
                );
              };
            }
          );
        }
      );
    '';

    systemd.services.logid-mx4 = {
      description = "Logitech Configuration Daemon (MX Master 4)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.logiops}/bin/logid -c /etc/logid-mx4.cfg";
        Restart = "always";
        RestartSec = "3s";
      };
    };
  };
}
