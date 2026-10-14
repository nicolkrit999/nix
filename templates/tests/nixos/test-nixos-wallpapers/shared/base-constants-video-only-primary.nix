# Primary "*" and a named entry carry only videoURL/gifURL (wallpaperURL empty); a third entry has an explicit still URL.
let
  base = import ./base-constants-empty.nix;
  sha = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
  empty = { wallpaperURL = ""; wallpaperSHA256 = ""; gifURL = ""; gifSHA256 = ""; videoURL = ""; videoSHA256 = ""; };
in
base // {
  wallpapers = [
    (empty // { targetMonitor = "*"; videoURL = "https://example.invalid/video-only-primary.mp4"; videoSHA256 = sha; })
    (empty // { targetMonitor = "DP-1"; gifURL = "https://example.invalid/gif-only-second.gif"; gifSHA256 = sha; })
    (empty // { targetMonitor = "HDMI-A-1"; wallpaperURL = "https://example.invalid/explicit-third.png"; wallpaperSHA256 = sha; })
  ];
}
