{ delib, ... }:
delib.module {
  name = "zram";

  nixos.always =
    { cfg, myconfig, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = myconfig.constants.zramPercent or 50;
        priority = 999;
      };
    };
}
