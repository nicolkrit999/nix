# Two declared outputs (DP-1 still, HDMI-A-1 video), no "*" fallback.
let
  base = import ./base-constants-mixed-fallback.nix;
  still = builtins.elemAt base.wallpapers 0;
  video = builtins.elemAt base.wallpapers 1;
in
base // {
  wallpapers = [
    (still // { targetMonitor = "DP-1"; })
    (video // { targetMonitor = "HDMI-A-1"; })
  ];
}
