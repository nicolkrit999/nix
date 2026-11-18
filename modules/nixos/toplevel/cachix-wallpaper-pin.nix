{ delib, lib, pkgs, ... }:
delib.module {
  name = "cachix-wallpaper-pin";

  nixos.always =
    { myconfig, ... }:
    let
      inherit (myconfig.constants) wallpapers fallbackWallpaperURL fallbackWallpaperSHA256;
      pairs = lib.concatMap
        (w: [
          { url = w.wallpaperURL; sha256 = w.wallpaperSHA256; }
          { url = w.gifURL; sha256 = w.gifSHA256; }
          { url = w.videoURL; sha256 = w.videoSHA256; }
        ])
        wallpapers
      ++ [{ url = fallbackWallpaperURL; sha256 = fallbackWallpaperSHA256; }];
      assets = lib.unique (lib.filter (p: p.url != "") pairs);
    in
    lib.mkIf myconfig.cachix.enable {
      system.build.wallpaperAssets = pkgs.linkFarm "wallpaper-assets" (
        lib.imap0
          (i: p: {
            name = "${toString i}-${(pkgs.fetchurl p).name}";
            path = pkgs.fetchurl p;
          })
          assets
      );
    };
}
