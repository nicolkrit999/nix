{ delib, ... }:
delib.module {
  name = "zram";
  options.zram = with delib; {
    enable = boolOption true;
    zramPercent = intOption 25; # 🌟 Moved here
  };

  # 🌟 Changed from 'always' to 'ifEnabled' so it actually obeys the toggle switch!
  nixos.ifEnabled =
    { cfg, ... }:
    {
      zramSwap = {
        enable = true;
        algorithm = "zstd";
        memoryPercent = cfg.zramPercent; # 🌟 Read from cfg
        priority = 999;
      };
    };
}
