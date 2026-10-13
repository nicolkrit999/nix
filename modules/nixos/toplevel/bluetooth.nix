{ delib, ... }:
delib.module {
  name = "bluetooth";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      autoEnableOnBoot = boolOption true;
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = cfg.autoEnableOnBoot;
      };

      services.blueman.enable = true;
    };
}
