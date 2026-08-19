{ delib, config, ... }:
delib.module {
  name = "krit.services.desktop.windows-mount";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      boot.supportedFilesystems = [ "ntfs3" ];

      fileSystems."/mnt/windows" = {
        device = "/dev/disk/by-uuid/7E70DDB470DD737F";
        fsType = "ntfs3";
        options = [
          "nofail"
          "noatime"
          "uid=${toString config.users.users.${myconfig.constants.user}.uid}"
          "gid=${toString config.users.groups.users.gid}"
          "umask=022"
          "windows_names"
        ];
      };
    };
}
