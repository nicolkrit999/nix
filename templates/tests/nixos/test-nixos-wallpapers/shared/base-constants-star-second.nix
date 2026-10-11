# Two entries, the "*" entry is NOT first; primaryWallpaper must still pick it.
let
  base = import ./base-constants-no-star.nix;
  a = builtins.elemAt base.wallpapers 0;
  b = builtins.elemAt base.wallpapers 1;
in
base // {
  wallpapers = [ a (b // { targetMonitor = "*"; }) ];
}
