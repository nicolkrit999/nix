{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      # 🌟 FIXED VARS
      lockWallpaper =
        if builtins.length myconfig.constants.wallpapers > 0 then
          (builtins.elemAt myconfig.constants.wallpapers 0).wallpaperURL
        else
          "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";

      # Fetch the timeout from your new Hypridle module (fallback to 600 if not enabled)
      idleTimeout = myconfig.services.hypridle.lockTimeout or 600;
    in
    {
      programs.plasma.kscreenlocker = {
        # Convert seconds to minutes for KDE
        timeout = builtins.floor (idleTimeout / 60);

        autoLock = true;
        lockOnResume = true;
        passwordRequired = true;
        passwordRequiredDelay = 10; # Grace period in seconds

        # 2. APPEARANCE
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
