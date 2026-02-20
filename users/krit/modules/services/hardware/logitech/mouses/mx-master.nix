{ delib, pkgs, ... }:
delib.module {
  name = "krit.services.logitech.mouses";
  options.krit.services.logitech.mouses = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    environment.etc."logid.cfg".text = ''
      devices: (
        {
          name: "MX Master 3S";
          smartshift: { on: true; threshold: 20; };
          dpi: 1200;

          # FIXME: The scroll wheel speed is still slow on bluetooth
          hiresscroll: { enabled: true; invert: false; target: false; };

          # Normalizing scroll sensitivity
          scrollwheel: {
              hires: true;
              invert: false;
              target: false;
              pixels_per_step: 2.0;
          };

          thumbwheel: {
            divert: true;
            invert: false;
            left: {
              mode: "OnInterval";
              interval: 3;
              action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; };
            };
            right: {
              mode: "OnInterval";
              interval: 3;
              action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; };
            };
          };

          buttons: (
            # Side Buttons mapped to Copy/Paste
            { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; }, # [cite: 38]
            { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; }  # [cite: 38]
          );
        }
      );
    '';
  };
}
