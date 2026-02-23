{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { myconfig, ... }:
    let
      monitorConfig = lib.concatStringsSep "\n" (
        builtins.map (w: ''
          [output."${if w.targetMonitor == "*" then "all" else w.targetMonitor}"]
          source = "Path"
          image = "${
            pkgs.fetchurl {
              url = w.wallpaperURL;
              sha256 = w.wallpaperSHA256;
            }
          }"
          filter_by_theme = false
        '') myconfig.constants.wallpapers
      );
    in
    {
      # Enable data control for clipboard tools
      home.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

      xdg.configFile."cosmic/com.system76.CosmicBackground/v1/all".text = ''
        ${monitorConfig}

        [workspace]
        source = "Output"
      '';
    };
}
