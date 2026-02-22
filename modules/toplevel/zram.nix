{ delib, ... }:
delib.module {
  name = "zram";
  options.zram = with delib; {
    enable = boolOption true;
    zramPercent = intOption 25;
  };

  nixos.ifEnabled =
    { cfg, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = cfg.zramPercent;
        priority = 999;
      };
    };
}
