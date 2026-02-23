# This module configures the KDE Plasma screen locker (kscreenlocker) using the community "plasma-manager" flake
{ delib
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      fallbackWp = lib.findFirst (w: w.targetMonitor == "*") (builtins.head myconfig.constants.wallpapers) myconfig.constants.wallpapers;
      idleTimeout = myconfig.services.hypridle.lockTimeout or 600;
    in
    {
      programs.plasma.kscreenlocker = {
        timeout = builtins.floor (idleTimeout / 60);

        autoLock = true;
        lockOnResume = true;
        passwordRequired = true;
        passwordRequiredDelay = 10;

        appearance = {
          wallpaperPictureOfTheDay = null;
          wallpaperSlideShow = null;

          wallpaper = pkgs.fetchurl {
            url = fallbackWp.wallpaperURL;
            sha256 = fallbackWp.wallpaperSHA256;
          };
          alwaysShowClock = true;
          showMediaControls = true;
        };
      };
    };
}
