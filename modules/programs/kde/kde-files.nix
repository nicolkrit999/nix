{ config, vars, ... }:
{
  programs.plasma.overrideConfig = false;

  programs.plasma.configFile = {
    "spectaclerc" = {
      "General" = {
        "screenshotLocation" = "file://${vars.screenshots}/";
        "filenameString" = "Screenshot_%Y%M%D_%H%m%S";
        "rememberLastScreenshotPath" = false;
      };
      "ImageSave" = {
        "imageSaveLocation" = "file://${vars.screenshots}/";
      };
    };
  };
}
