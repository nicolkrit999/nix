{ delib
, lib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "krit.programs.dolphin";
  options = delib.singleEnableOption false;

  home.ifEnabled =
    { myconfig
    , ...
    }:
    let
      homeDir = "/home/${myconfig.constants.user}";

      extraPlaces = [
        { title = "momentary"; path = "${homeDir}/momentary"; icon = "folder"; }
        { title = "mnt"; path = "/mnt"; icon = "folder-mount"; }
      ];

      placeBookmark = { title, path, icon }:
        ''<bookmark href="file://${path}"><title>${title}</title><info><metadata owner="http://freedesktop.org"><bookmark:icon name="${icon}"/></metadata></info></bookmark>'';

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
          ${lib.concatMapStringsSep "\n" placeBookmark extraPlaces}
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

      placesFile = pkgs.writeText "user-places.xbel" placesXml;
    in
    {
      home.packages = with pkgs; [
        kdePackages.kio-extras
        kdePackages.kio-fuse
        kdePackages.kdegraphics-thumbnailers
        kdePackages.ffmpegthumbs
      ];

      # plasma-manager resets dolphinrc on every activation when overrideConfig is on
      programs.plasma.resetFilesExclude = [ "dolphinrc" ];

      xdg.configFile."dolphinrc" = {
        force = true;
        text = ''
          [General]
          ShowFullPath=true
          ConfirmDelete=true
          ViewPropsTimestamp=2025,1,1,12,0,0.000

          [KFileDialog Settings]
          PlacesIconsAutoResize=true
          PlacesIconsStaticSize=22
        '';
      };

      home.activation.createDolphinPlaces =
        inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ]
          ''
            places="${homeDir}/.local/share/user-places.xbel"
            if [ ! -f "$places" ]; then
              run install -D -m 644 ${placesFile} "$places"
            else
              # existing file: append only the extra places it lacks, keeping Dolphin's own edits
              ${lib.concatMapStrings (p: ''
                if ! grep -qF 'href="file://${p.path}"' "$places"; then
                  run sed -i 's|</xbel>|${placeBookmark p}\n</xbel>|' "$places"
                fi
              '') extraPlaces}
            fi
          '';
    };
}
