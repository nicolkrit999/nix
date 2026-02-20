{ delib, ... }:
delib.module {
  name = "system.zram";

  nixos.always =
    { nixos, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = nixos.constants.zramPercent or 50;
        priority = 999;
      };
    };
}
