{
  delib,
  ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { cfg, nixos, ... }:
    {
      programs.plasma.overrideConfig = false;

      programs.plasma.configFile = {
        "spectaclerc" = {
          "General" = {
            # 🌟 FIXED VARS
            "screenshotLocation" = "file://${nixos.constants.screenshots}/";
            "filenameString" = "Screenshot_%Y%M%D_%H%m%S";
            "rememberLastScreenshotPath" = false;
          };
          "ImageSave" = {
            "imageSaveLocation" = "file://${nixos.constants.screenshots}/";
          };
        };
      };
    };
}
