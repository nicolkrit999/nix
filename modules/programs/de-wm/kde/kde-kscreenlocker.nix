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
      lockWallpaper =
        if builtins.length myconfig.constants.wallpapers > 0 then
          (builtins.elemAt myconfig.constants.wallpapers 0).wallpaperURL
        else
          "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";

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
            url = lockWallpaper;
            sha256 =
              if (builtins.length myconfig.constants.wallpapers) > 0 then
                (builtins.elemAt myconfig.constants.wallpapers 0).wallpaperSHA256
              else
                lib.fakeSha256;
          };
          alwaysShowClock = true;
          showMediaControls = true;
        };
      };
    };
}
