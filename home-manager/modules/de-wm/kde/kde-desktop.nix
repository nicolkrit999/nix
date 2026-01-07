{ lib, ... }:
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
    # 2. ICONS
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
      # Enabled (standard size)

      # 3. PREVIEW PLUGINS
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

    # 4. DESKTOP WIDGETS
    widgets = [
    ];
  };
}
