{ delib
, lib
, pkgs
, ...
}:
delib.module {
  name = "programs.cosmic";

  home.ifEnabled =
    { myconfig, ... }:
    let
      c = myconfig.constants;

      isSafeOutput = n: n != "*" && builtins.match "[A-Za-z0-9_.:-]+" n != null;
      named = lib.filter (w: isSafeOutput w.targetMonitor) c.wallpapers;
      skipped = lib.filter (w: w.targetMonitor != "*" && !(isSafeOutput w.targetMonitor)) c.wallpapers;

      fetch = w:
        let useFallback = w.wallpaperURL == ""; in
        "${pkgs.fetchurl {
          url = if useFallback then c.fallbackWallpaperURL else w.wallpaperURL;
          sha256 = if useFallback then c.fallbackWallpaperSHA256 else w.wallpaperSHA256;
        }}";

      mkWallpaper = output: w: {
        inherit output;
        source = {
          __type = "enum";
          variant = "Path";
          value = [ (fetch w) ];
        };
        filter_by_theme = false;
        filter_method = {
          __type = "enum";
          variant = "Lanczos";
        };
        scaling_mode = {
          __type = "enum";
          variant = "Zoom";
        };
        sampling_method = {
          __type = "enum";
          variant = "Alphanumeric";
        };
        rotation_frequency = 3600;
      };

      wallpapers =
        if named == [ ] then
          [ (mkWallpaper "all" c.primaryWallpaper) ]
        else
          map (w: mkWallpaper w.targetMonitor w) named;
    in
    {
      wayland.desktopManager.cosmic.wallpapers = lib.warnIf (skipped != [ ])
        "cosmic wallpapers: skipping targetMonitor entries that are not COSMIC output names: ${builtins.concatStringsSep ", " (map (w: w.targetMonitor) skipped)}"
        wallpapers;
    };
}
