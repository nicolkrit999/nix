{ config, pkgs, ... }:

let
  # ----------------------------------------------------------------
  # 🔌 USB CONFIGURATION (Bolt Receiver)
  # ----------------------------------------------------------------
  usbConfig = ''
    smartshift: { on: true; threshold: 20; };
    dpi: 1200;

    # KEEP HIRES FALSE FOR USB
    hiresscroll: { hires: false; invert: false; target: false; };

    thumbwheel: {
      divert: true;
      invert: false;
      left: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
      right: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
    };
    buttons: (
      { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
      { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; },
      { cid: 0xc3; action: { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; }
    );
  '';

  # ----------------------------------------------------------------
  # 🔵 BLUETOOTH CONFIGURATION
  # ----------------------------------------------------------------
  btConfig = ''
    smartshift: { on: true; threshold: 20; };
    dpi: 1200;

    # TURN HIRES ON FOR BLUETOOTH
    # This sends more scroll events, making it feel faster/smoother
    # to compensate for Bluetooth latency.
    hiresscroll: { hires: true; invert: false; target: false; };

    thumbwheel: {
      divert: true;
      invert: false;
      left: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEDOWN"]; }; };
      right: { mode: "OnInterval"; interval: 3; action: { type: "Keypress"; keys: ["KEY_VOLUMEUP"]; }; };
    };
    buttons: (
      { cid: 0x53; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_C"]; }; },
      { cid: 0x56; action: { type: "Keypress"; keys: ["KEY_LEFTCTRL", "KEY_V"]; }; },
      { cid: 0xc3; action: { type: "Keypress"; keys: ["KEY_LEFTMETA"]; }; }
    );
  '';

in
{
  boot.kernelModules = [
    "uinput"
    "hid-logitech-hidpp"
  ];
  environment.systemPackages = [ pkgs.logiops ];

  # Apply distinct configs to distinct names
  environment.etc."logid.cfg".text = ''
    devices: (
      {
        name: "MX Master 3S";
        ${btConfig}
      },
      {
        name: "Wireless Mouse MX Master 3S";
        ${usbConfig}
      }
    );
  '';

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="input", ATTR{name}=="Logitech MX Master 3S", RUN+="${pkgs.systemd}/bin/systemctl restart logid.service"
    ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="046d", ATTRS{idProduct}=="c548", RUN+="${pkgs.systemd}/bin/systemctl restart logid.service"
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
}
