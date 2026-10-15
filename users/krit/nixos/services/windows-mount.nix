{ delib, config, ... }:
delib.module {
  name = "krit.services.windows-mount";
  options = with delib; moduleOptions {
    enable = boolOption false;
    # No default on purpose: an unmapped host must fail the assertion, not mount nothing.
    uuid = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      assertions = [
        {
          assertion = cfg.uuid != "";
          message = ''
            krit.services.windows-mount is enabled on host "${myconfig.constants.hostname}", but
            krit.services.windows-mount.uuid is empty. Set the Windows partition UUID
            in the host config (or disable windows-mount.enable).
          '';
        }
      ];

      boot.supportedFilesystems = [ "ntfs3" ];

      fileSystems."/mnt/windows" = {
        device = "/dev/disk/by-uuid/${cfg.uuid}";
        fsType = "ntfs3";
        options = [
          "nofail"
          "noatime"
          "uid=${toString config.users.users.${myconfig.constants.user}.uid}"
          "gid=${toString config.users.groups.${config.users.users.${myconfig.constants.user}.group}.gid}"
          "umask=022"
          "windows_names"
        ];
      };
    };
}
