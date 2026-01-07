{
  pkgs,
  lib,
  vars,
  ...
}:

let
  # Fallback to a default image if the list is empty
  lockWallpaper =
    if builtins.length vars.wallpapers > 0 then
      (builtins.elemAt vars.wallpapers 0).wallpaperURL
    else
      "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Kay/contents/images/1080x1920.png";
in
{
  programs.plasma.kscreenlocker = {
    # Convert seconds (from idleConfig) to minutes for Plasma
    timeout = if vars.idleConfig != null then builtins.floor (vars.idleConfig.lockTimeout / 60) else 10;

    autoLock = true;
    lockOnResume = true;
    passwordRequired = true;
    passwordRequiredDelay = 10; # Grace period in seconds

    # 2. APPEARANCE
    appearance = {
      wallpaperPictureOfTheDay = null;
      wallpaperSlideShow = null;

      # Use the wallpaper of the primary monitor
      wallpaper = pkgs.fetchurl {
        url = lockWallpaper;
        sha256 =
          if (builtins.length (vars.wallpapers or [ ])) > 0 then
            (builtins.elemAt vars.wallpapers 0).wallpaperSHA256
          else
            lib.fakeSha256;
      };

      alwaysShowClock = true;
      showMediaControls = true;
    };
  };
}
