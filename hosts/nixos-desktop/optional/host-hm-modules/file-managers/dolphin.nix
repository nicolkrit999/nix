{
  pkgs,
  config,
  lib,
  ...
}:
let
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
      <bookmark href="file://${config.home.homeDirectory}">
        <title>Home</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="user-home"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/Documents">
        <title>Documents</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-documents"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/Downloads">
        <title>Downloads</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-download"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/Pictures">
        <title>Pictures</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-pictures"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/nixOS">
        <title>nixOS</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="nix-snowflake"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/dotfiles">
        <title>dotfiles</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-config"/></metadata></info>
      </bookmark>
      <bookmark href="file://${config.home.homeDirectory}/developing-projects">
        <title>developing-projects</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="folder-development"/></metadata></info>
      </bookmark>
      <bookmark href="file:///mnt/nicol_nas">
        <title>NAS</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="network-server"/></metadata></info>
      </bookmark>
      <bookmark href="trash:/">
        <title>Trash</title>
        <info><metadata owner="http://freedesktop.org"><bookmark:icon name="user-trash"/></metadata></info>
      </bookmark>
    </xbel>
  '';
in
{
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

  home.activation.createDolphinPlaces = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -f "${config.home.homeDirectory}/.local/share/user-places.xbel" ]; then
          echo "Creating Dolphin Places file..."
          mkdir -p "${config.home.homeDirectory}/.local/share"
          cat > "${config.home.homeDirectory}/.local/share/user-places.xbel" <<EOF
    ${placesXml}
    EOF
        fi
  '';
}
