{ delib
, pkgs
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      primaryWp = myconfig.constants.primaryWallpaper;
      useFallback = primaryWp.wallpaperURL == "";
      idleTimeout = myconfig.services.hypridle.lockTimeout;
    in
    {
      programs.plasma.kscreenlocker = {
        timeout = idleTimeout / 60;

        autoLock = true;
        lockOnResume = true;
        passwordRequired = true;
        passwordRequiredDelay = 10;

        appearance = {
          wallpaper = pkgs.fetchurl {
            url = if useFallback then myconfig.constants.fallbackWallpaperURL else primaryWp.wallpaperURL;
            sha256 = if useFallback then myconfig.constants.fallbackWallpaperSHA256 else primaryWp.wallpaperSHA256;
          };
          alwaysShowClock = true;
          showMediaControls = true;
        };
      };
    };
}
