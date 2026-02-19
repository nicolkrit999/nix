{ vars, ... }:
{
  zramSwap = {
    enable = true;

    # Algorithm Selection:
    # "lz4"  = Fastest, lower compression. Prioritizes speed/latency.
    # "zstd" = Slower, better compression. Best for lower RAM.
    algorithm = "zstd";
    memoryPercent = vars.zramPercent or 50; # Default to 25% of RAM

    priority = 999; # High priority to prioritize zram over disk swap
  };
}
