{ delib, ... }:
delib.module {
  name = "zram";
  options.zram = with delib; {
    enable = boolOption true;
  };

  # FIX: Fix evaluation warnings
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
