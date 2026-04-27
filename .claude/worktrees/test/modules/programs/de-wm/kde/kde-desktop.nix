# Configure kde plasma desktop appearance using the community "plasma-manager" flake
{ delib
, ...
}:
delib.module {
  name = "programs.kde";

  home.ifEnabled =
    {
      programs.plasma.desktop = {
        mouseActions = {
          # Right Click -> Context Menu
          rightClick = "contextMenu";
          # Scroll Wheel -> Switch Virtual Desktops
          verticalScroll = "switchVirtualDesktop";
          # Middle Click -> Paste (Standard Linux behavior)
          middleClick = "paste";
        };
        icons = {
          arrangement = "topToBottom";
          alignment = "left";
          lockInPlace = false; # Allow manual moving if needed

          sorting = {
            mode = "name";
            foldersFirst = true;
          };

          size = 3; # from 0 to 6

          folderPreviewPopups = true;

          # PREVIEW PLUGINS
          previewPlugins = [
            "imagethumbnail"
            "jpegthumbnail"
            "fontthumbnail"
            "opendocumentthumbnail"
            "gsthumbnail"
            "comicbookthumbnail"
            "audiothumbnail"
            "ebookthumbnail"
          ];
        };

        # DESKTOP WIDGETS
        widgets = [ ];
      };
    };
}
