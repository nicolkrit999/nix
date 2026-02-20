{
  delib,
  pkgs,
  lib,
  nixos,
  ...
}:
delib.module {
  name = "programs.cosmic";
  options.programs.cosmic = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    let
      activeMonitors = builtins.filter (m: !(lib.hasInfix "disable" m)) nixos.constants.monitors;
      monitorPorts = map (m: builtins.head (lib.splitString "," m)) activeMonitors;

      wallpaperFiles = map (
        wp:
        "${pkgs.fetchurl {
          url = wp.wallpaperURL;
          sha256 = wp.wallpaperSHA256;
        }}"
      ) nixos.constants.wallpapers;

      # If there are more monitors than wallpapers, reuse the last wallpaper
      getWallpaper =
        index:
        if index < builtins.length wallpaperFiles then
          builtins.elemAt wallpaperFiles index
        else
          lib.last wallpaperFiles;

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
