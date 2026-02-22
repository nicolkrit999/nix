{
  delib,
  pkgs,
  inputs,
  ...
}:
delib.module {
  name = "krit.programs.dolphin";
  options.krit.programs.dolphin = with delib; {
    enable = boolOption false;
  };

  home.ifEnabled =
    {
      myconfig,
      ...
    }:
    let
      homeDir = "/home/${myconfig.constants.user}";

      placesXml = ''
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE xbel>
        <xbel xmlns:bookmark="http://www.freedesktop.org/standards/desktop-bookmarks" xmlns:kdefile="http://www.kde.org/standards/kdefile">
          <info>
            <metadata owner="http://www.kde.org">
              <kde_places_version>4</kde_places_version>
              <GroupState-Places-IsHidden>false</GroupState-Places-IsHidden>
              <GroupState-Remote-IsHidden>false</GroupState-Remote-IsHidden>
              <GroupState-Devices-IsHidden>false</GroupState-Devices-IsHidden>
              <GroupState-RemovableDevices-IsHidden>false</GroupState-RemovableDevices-IsHidden>
            </metadata>
          </info>
          <bookmark href="file://${homeDir}">
            <title>Home</title>
            <info><metadata owner="http://freedesktop.org"><bookmark:icon name="user-home"/></metadata></info>
          </bookmark>
          <bookmark href="file://${homeDir}/Documents">
            <title>Documents</title>
            <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-documents"/></metadata></info>
          </bookmark>
          <bookmark href="file://${homeDir}/Downloads">
            <title>Downloads</title>
            <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-downloads"/></metadata></info>
          </bookmark>
          <bookmark href="remote:/">
            <title>Network</title>
            <info><metadata owner="http://freedesktop.org"><bookmark:icon name="network-workgroup"/></metadata></info>
          </bookmark>
          <bookmark href="trash:/">
            <title>Trash</title>
            <info><metadata owner="http://freedesktop.org"><bookmark:icon name="user-trash"/></metadata></info>
          </bookmark>
        </xbel>
      '';
    in
    {
      home.packages = with pkgs; [
        kdePackages.kio-extras
        kdePackages.kio-fuse
      ];

      xdg.configFile."dolphinrc".text = ''
        [General]
        ShowFullPath=true
        ConfirmDelete=true
        ViewPropsTimestamp=2025,1,1,12,0,0.000

        [KFileDialog Settings]
        PlacesIconsAutoResize=true
        PlacesIconsStaticSize=22

        [PreviewSettings]
        Plugins=dolphingitplugin,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorauthmubnail,malthumbnail,mdthumbnail,mobithumbnail,mp3thumbnail,opendocumentthumbnail,palapeli_thumbnailer,pdfthumbnail,rawthumbnail,svgthumbnail,texthumbnail,ffmpegthumbs,videothumbnail,windowsimagethumbnail
      '';

      home.activation.createDolphinPlaces =
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
          ''
            if [ ! -f "${homeDir}/.local/share/user-places.xbel" ]; then
              echo "Creating Dolphin Places file..."
              mkdir -p "${homeDir}/.local/share"
              echo '${placesXml}' > "${homeDir}/.local/share/user-places.xbel"
            fi
          '';
    };
}
