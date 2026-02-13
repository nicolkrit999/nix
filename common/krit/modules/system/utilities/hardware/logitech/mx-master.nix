{
  # 🖱️ MX Master 3S Configuration
  sharedConfig = ''
    smartshift: { on: true; threshold: 20; };
    dpi: 1200;

    hiresscroll: { hires: false; invert: false; target: false; };

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
      { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
      { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; }
    );
  '';
}
