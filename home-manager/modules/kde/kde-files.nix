{ config, screenshots, ... }:
{
  programs.plasma.overrideConfig = false;

  programs.plasma.configFile = {
    "spectaclerc" = {
      "General" = {
        "screenshotLocation" = "file://${screenshots}/";
        "filenameString" = "Screenshot_%Y%M%D_%H%m%S";

        # Ensure it doesn't try to remember the last used path
        "rememberLastScreenshotPath" = false;
      };

      # Force auto-save to that location without asking
      "ImageSave" = {
        "imageSaveLocation" = "file://${screenshots}/";
      };
    };
  };
}
