{ delib, ... }:
delib.module {
  name = "zram";

  nixos.always =
    { constants, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = constants.zramPercent or 50;
        priority = 999;
      };
    };
}
