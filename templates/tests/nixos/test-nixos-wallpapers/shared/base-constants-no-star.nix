# Two declared outputs, no "*" entry, distinct URL basenames; catppuccin off so hyprlock builds its own background.
let
  base = import ./base-constants-empty.nix;
  entry = name: monitor: {
    targetMonitor = monitor;
    wallpaperURL = "https://example.invalid/${name}.png";
    wallpaperSHA256 = "14syikj4d8j8vaqshp1ya58sia18gmpi278lmhfnhgid8fxa0y4f";
    gifURL = "";
    gifSHA256 = "";
  };
in
base // {
  wallpapers = [ (entry "first-entry" "DP-1") (entry "second-entry" "HDMI-A-1") ];
}
