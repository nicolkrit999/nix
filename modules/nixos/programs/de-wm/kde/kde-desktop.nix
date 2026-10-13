{ delib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      programs.plasma.desktop = {
        mouseActions = {
          rightClick = "contextMenu";
          verticalScroll = "switchVirtualDesktop";
          middleClick = "paste";
        };
        icons = {
          arrangement = "topToBottom";
          alignment = "left";
          lockInPlace = false;

          sorting = {
            mode = "name";
            foldersFirst = true;
          };

          size = 3; # from 0 to 6

          folderPreviewPopups = true;

          previewPlugins = [
            "audiothumbnail"
            "comicbookthumbnail"
            "ebookthumbnail"
            "fontthumbnail"
            "gsthumbnail"
            "imagethumbnail"
            "jpegthumbnail"
            "opendocumentthumbnail"
          ];
        };

        widgets = [ ];
      };
    };
}
