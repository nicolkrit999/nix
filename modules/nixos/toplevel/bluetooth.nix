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

        settings = {
          Policy = {
            AutoEnable = if cfg.autoEnableOnBoot then "true" else "false";
          };
        };
      };

      services.blueman.enable = true;
    };
}
