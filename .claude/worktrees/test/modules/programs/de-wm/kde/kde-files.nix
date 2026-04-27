# configure Low-level access to changing Plasma settings using the community "plasma-manager" flake
{ delib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { myconfig
    , ...
    }:
    {
      programs.plasma.overrideConfig = false;

      programs.plasma.configFile = {
        "spectaclerc" = {
          "General" = {
            # 🌟 FIXED VARS
            "screenshotLocation" = "file://${myconfig.constants.screenshots}/";
            "filenameString" = "Screenshot_%Y%M%D_%H%m%S";
            "rememberLastScreenshotPath" = false;
          };
          "ImageSave" = {
            "imageSaveLocation" = "file://${myconfig.constants.screenshots}/";
          };
        };
      };
    };
}
