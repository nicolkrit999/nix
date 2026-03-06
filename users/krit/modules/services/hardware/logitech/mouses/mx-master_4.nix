{ delib, ... }:
delib.module {
  name = "krit.services.logitech.mouses.mx-master-4";
  options.krit.services.logitech.mouses.mx-master-4 = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    services.keyd = {
      keyboards = {
        mxmaster4 = {
          ids = [ "046d:b042" ];
          settings = {
            main = {
              mouseforward = "C-z";
            };
          };
        };
      };
    };

    myconfig.krit.services.logitech.logidDeviceBlocks = [
      ''
        {
          name: "MX Master 4";
          productId: 0xb042;

          smartshift: { on: true; threshold: 20; };
          dpi: 1200;
          hiresscroll: { enabled: true; invert: false; target: false; };

          scrollwheel: {
              hires: true;
              invert: false;
              target: false;
              pixels_per_step: 2.0;
          };

          thumbwheel: {
            divert: true;
            invert: false;
            left: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
            right: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
          };

          buttons: (
            { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
            { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; },
            {
              cid: 0xc3;
              action: {
                type: "Gestures";
                threshold: 15;
                gestures: (
                  { direction: "None";  mode: "OnRelease"; action: { type: "Keypress"; keys: ["KEY_PLAYPAUSE"]; } },
                  { direction: "Left";  mode: "OnRelease"; action: { type: "Keypress"; keys: ["KEY_F13"]; } },
                  { direction: "Right"; mode: "OnRelease"; action: { type: "Keypress"; keys: ["KEY_F14"]; } },
                  { direction: "Up";    mode: "OnRelease"; action: { type: "Keypress"; keys: ["KEY_F15"]; } },
                  { direction: "Down";  mode: "OnRelease"; action: { type: "Keypress"; keys: ["KEY_F16"]; } }
                );
              };
            }
          );
        }
      ''
    ];
  };
}
