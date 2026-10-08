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
      programs.plasma.configFile = {
        "spectaclerc" = {
          "General" = {
            "screenshotLocation" = "file://${myconfig.constants.screenshots}/";
            "filenameString" = "Screenshot_%Y%M%D_%H%m%S";
            "rememberLastScreenshotPath" = false;
          };
          "ImageSave" = {
            "imageSaveLocation" = "file://${myconfig.constants.screenshots}/";
          };
        };
        "kcmfonts"."General"."forceFontDPI" = 0;
      };

      dconf.settings."org/gnome/desktop/interface".text-scaling-factor = 1.0;
    };
}
