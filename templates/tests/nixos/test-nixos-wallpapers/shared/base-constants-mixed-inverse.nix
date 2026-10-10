# Inverse of base-constants-mixed-fallback.nix: DP-1 is the video, "*" the still.
let
  base = import ./base-constants-mixed-fallback.nix;
  still = builtins.elemAt base.wallpapers 0;
  video = builtins.elemAt base.wallpapers 1;
in
base // {
  wallpapers = [
    (video // { targetMonitor = "DP-1"; })
    (still // { targetMonitor = "*"; })
  ];
}
