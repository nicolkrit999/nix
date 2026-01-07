{ pkgs, ... }:
{

  # 1. Force QT applications to use Wayland
  home.sessionVariables = {
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  # 2. Keybindings & Settings
  # Dolphin configuration is stored in ~/.config/dolphinrc and ~/.config/khotkeysrc
  xdg.configFile."dolphinrc" = {
    text = ''
      [General]
      ShowFullPath=true
      ViewPropsTimestamp=2025,1,1,12,0,0.000

      [KFileDialog Settings]
      PlacesIconsAutoResize=true
      PlacesIconsStaticSize=22

      [PreviewSettings]
      Plugins=dolphingitplugin,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorauthmubnail,malthumbnail,mdthumbnail,mobithumbnail,mp3thumbnail,opendocumentthumbnail,palapeli_thumbnailer,pdfthumbnail,rawthumbnail,svgthumbnail,texthumbnail,ffmpegthumbs,videothumbnail,windowsimagethumbnail
    '';
  };
}
