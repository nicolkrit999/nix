{ delib, ... }:
delib.module {
  name = "zram";
  options =
    with delib;
    moduleOptions {
      enable = boolOption true;
      zramPercent = intOption 25;
    };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      zramSwap = {
        enable = true;
        memoryPercent = cfg.zramPercent;
        priority = 999;
      };
    };
}
