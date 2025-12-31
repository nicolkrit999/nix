{ vars, ... }:
{
  zramSwap = {
    enable = true;

    # Algorithm Selection:
    # "lz4"  = Fastest, lower compression. Prioritizes speed/latency.
    # "zstd" = Slower, better compression. Best for lower RAM.
    algorithm = "zstd"; # Changed to zstd as it's generally better for modern setups
    memoryPercent = vars.zramPercent;

    priority = 999; # High priority to prioritize zram over disk swap
  };
}
