# Wallpaper lists for the hyprlock per-monitor checks; catppuccin off (except desktopCatppuccin) so hyprlock builds its own backgrounds.
# Distinct URL basenames so store paths identify which entry a background used.
let
  base = import ./base-constants-empty.nix;
  sha = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
  entry = name: monitor: {
    targetMonitor = monitor;
    wallpaperURL = "https://example.invalid/${name}.png";
    wallpaperSHA256 = sha;
    gifURL = "";
    gifSHA256 = "";
  };
  videoOnly = name: monitor: {
    targetMonitor = monitor;
    wallpaperURL = "";
    wallpaperSHA256 = "";
    gifURL = "";
    gifSHA256 = "";
    videoURL = "https://example.invalid/${name}.mp4";
    videoSHA256 = sha;
  };
  with' = ws: base // { wallpapers = ws; };
in
{
  desktop = with' [ (entry "lock-dp1" "DP-1") (entry "lock-dp2" "DP-2") (entry "lock-star" "*") ];
  laptop = with' [ (entry "lock-edp1" "eDP-1") (entry "lock-star" "*") ];
  desktopCatppuccin = (with' [ (entry "lock-dp1" "DP-1") (entry "lock-dp2" "DP-2") (entry "lock-star" "*") ]) // {
    inherit (import ./base-constants-static.nix) theme;
  };
  noStarOne = with' [ (entry "lock-edp1" "eDP-1") ];
  noStarThree = with' [ (entry "lock-dp1" "DP-1") (entry "lock-dp2" "DP-2") (entry "lock-dp3" "DP-3") ];
  starOnly = with' [ (entry "lock-star" "*") ];
  descAndVideo = with' [
    (videoOnly "lock-dp3-video" "DP-3")
    (entry "lock-desc" "desc:Foo Bar 123")
    (videoOnly "lock-star-video" "*")
  ];
}
