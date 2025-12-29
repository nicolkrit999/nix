{
  lib,
  pkgs,
  cosmic,
  monitors,
  wallpapers,
  ...
}:
let
  # 1. PARSE MONITOR NAMES
  # "DP-1,3840x2160..." -> "DP-1"
  # filter out disabled monitors first
  activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) monitors;
  monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;

  # 2. FETCH WALLPAPERS
  wallpaperFiles = map (
    wp:
    "${pkgs.fetchurl {
      url = wp.wallpaperURL;
      sha256 = wp.wallpaperSHA256;
    }}"
  ) wallpapers;

  # 3. HELPER: GET WALLPAPER BY INDEX
  # If there are more monitors than wallpapers, reuse the last wallpaper
  getWallpaper =
    index:
    if index < builtins.length wallpaperFiles then
      builtins.elemAt wallpaperFiles index
    else
      lib.last wallpaperFiles;

  # 4. GENERATE TOML CONFIGURATION
  # Creates a [output."PORT_NAME"] block for each monitor
  monitorConfig = lib.concatStringsSep "\n" (
    lib.lists.imap0 (i: port: ''
      [output."${port}"]
      source = "Path"
      image = "${getWallpaper i}"
      filter_by_theme = false
    '') monitorPorts
  );

in
{
  config = lib.mkIf cosmic {
    # Enable data control for clipboard tools
    home.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

    xdg.configFile."cosmic/com.system76.CosmicBackground/v1/all".text = ''
      ${monitorConfig}

      # Fallback for any monitor not explicitly named above
      [output."*"]
      source = "Path"
      image = "${builtins.head wallpaperFiles}"
      filter_by_theme = false
    '';
  };
}
