{ delib
, config
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      sans = config.stylix.fonts.sansSerif.name;
      mono = config.stylix.fonts.monospace.name;
      pointSize = config.stylix.fonts.sizes.applications;
      sansFont = { family = sans; inherit pointSize; };
      # I-22: spectacle reads file:// URLs literally, so $HOME must be expanded here
      screenshotsDir = myconfig.constants.screenshotsAbs;
    in
    {
      home.packages = [ config.stylix.fonts.sansSerif.package ];
      fonts.fontconfig.enable = true;

      programs.plasma.fonts = {
        general = sansFont;
        menu = sansFont;
        toolbar = sansFont;
        windowTitle = sansFont;
        small = { family = sans; pointSize = pointSize - 2; };
        fixedWidth = { family = mono; inherit pointSize; };
      };

      programs.plasma.configFile = {
        "spectaclerc" = {
          "General" = {
            "screenshotLocation" = "file://${screenshotsDir}/";
            "filenameString" = "Screenshot_%Y%M%D_%H%m%S";
            "rememberLastScreenshotPath" = false;
          };
          "ImageSave" = {
            "imageSaveLocation" = "file://${screenshotsDir}/";
          };
        };
        "kcmfonts"."General"."forceFontDPI" = 0;
      };

      dconf.settings."org/gnome/desktop/interface".text-scaling-factor = 1.0;
    };
}
