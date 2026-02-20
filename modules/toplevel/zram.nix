{ delib, ... }:
delib.module {
  name = "system.zram";

  myconfig.always =
    { myconfig, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = myconfig.constants.zramPercent or 50;
        priority = 999;
      };
    };
}
