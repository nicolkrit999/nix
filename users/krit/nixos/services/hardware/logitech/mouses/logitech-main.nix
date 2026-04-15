{ delib, ... }:
delib.module {
  name = "krit.services.logitech";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    hardware.logitech.wireless.enable = true;
    hardware.logitech.wireless.enableGraphical = true;

    boot.kernelModules = [
      "hid-logitech-hidpp"
    ];
  };
}
