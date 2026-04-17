{ delib, pkgs, lib, ... }:
delib.module {
  name = "krit.services.logitech";
  options = with delib; moduleOptions {
    enable = boolOption false;
    mouses = {
      mx-master-3s.enable = boolOption false;
      mx-master-4.enable = boolOption false;
      superlight.enable = boolOption false;
    };
  };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      mouses = cfg.mouses;

      deviceBlocks = {
        mx-master-3s = ''
          {
            name: "MX Master 3S";
            productId: 0xb034;
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
              {
                cid: 0xc3;
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
        '';

        mx-master-4 = ''
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
        '';
      };

      enabledBlocks = lib.concatLists [
        (lib.optional mouses.mx-master-3s.enable deviceBlocks.mx-master-3s)
        (lib.optional mouses.mx-master-4.enable deviceBlocks.mx-master-4)
      ];

      udevRules = lib.concatStrings [
        (lib.optionalString mouses.mx-master-3s.enable ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/control}="on"
        '')
        (lib.optionalString mouses.mx-master-4.enable ''
          ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/control}="on"
        '')
      ];
    in
    {
      hardware.logitech.wireless.enable = true;
      hardware.logitech.wireless.enableGraphical = true;

      environment.systemPackages = with pkgs; [
        logiops
        libinput
        evtest
        keyd
      ];

      boot.kernelModules = [
        "hid-logitech-hidpp"
        "uinput"
      ];

      services.udev.extraRules = udevRules;

      services.keyd.enable = lib.mkIf mouses.superlight.enable true;
      services.keyd.keyboards = lib.mkIf mouses.superlight.enable {
        superlight = {
          ids = [ "046d:c54d" ];
          settings = {
            main = {
              mouse1 = "C-c";
              mouse2 = "C-v";
            };
          };
        };
      };

      environment.etc."logid.cfg".text = ''
        devices: (
          ${builtins.concatStringsSep ",\n" enabledBlocks}
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
