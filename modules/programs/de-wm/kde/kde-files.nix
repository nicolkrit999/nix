{
  delib,
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
