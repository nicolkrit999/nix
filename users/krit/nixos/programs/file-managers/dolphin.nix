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

      trashHref = "trash:/";

      places = [
        { title = "Home"; href = "file://${homeDir}"; icon = "user-home"; }
        { title = "Documents"; href = "file://${homeDir}/Documents"; icon = "folder-documents"; }
        { title = "Pictures"; href = "file://${homeDir}/Pictures"; icon = "folder-pictures"; }
        { title = "nix"; href = "file://${homeDir}/${myconfig.constants.flakeDir}"; icon = "folder"; }
        { title = "Downloads"; href = "file://${homeDir}/Downloads"; icon = "folder-downloads"; }
        { title = "momentary"; href = "file://${homeDir}/momentary"; icon = "folder"; }
        { title = "mnt"; href = "file:///mnt"; icon = "folder-mount"; }
        { title = "Network"; href = "remote:/"; icon = "network-workgroup"; }
        { title = "Trash"; href = trashHref; icon = "user-trash"; }
      ];

      placeBookmark = { title, href, icon }:
        ''<bookmark href="${href}"><title>${title}</title><info><metadata owner="http://freedesktop.org"><bookmark:icon name="${icon}"/></metadata></info></bookmark>'';

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
          ${lib.concatMapStringsSep "\n  " placeBookmark places}
        </xbel>
      '';

      placesSync = pkgs.writeShellApplication {
        name = "dolphin-places-sync";
        runtimeInputs = [ pkgs.python3 ];
        text = ''
          exec python3 -I ${./dolphin-places-sync.py} "$@"
        '';
      };

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
            run ${lib.getExe placesSync} ${placesFile} "${homeDir}/.local/share/user-places.xbel" --last ${lib.escapeShellArg trashHref} \
              || warnEcho "dolphin places not reordered, user-places.xbel left untouched"
          '';
    };
}
