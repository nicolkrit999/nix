{ delib, config, ... }:
delib.module {
  name = "krit.services.windows-mount";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      # Windows partition UUID varies per host - keep this explicit rather
      # than defaulting, so an unmapped host fails loudly instead of
      # mounting nothing (or the wrong partition).
      uuidByHostname = {
        nixos-desktop = "7E70DDB470DD737F";
        nixos-laptop = "26C47F73C47F43D9"; # 2T NTFS = Windows C:, not the 845M recovery partition
      };

      hostname = myconfig.constants.hostname;
      hasUuid = uuidByHostname ? ${hostname};
    in
    {
      assertions = [
        {
          assertion = !cfg.enable || hasUuid;
          message = ''
            krit.services.windows-mount is enabled on host "${hostname}", but
            no Windows partition UUID is mapped for it in
            users/krit/nixos/services/windows-mount.nix. Add an entry to
            uuidByHostname for this host (or disable windows-mount.enable).
          '';
        }
      ];

      boot.supportedFilesystems = [ "ntfs3" ];

      fileSystems."/mnt/windows" = {
        device = "/dev/disk/by-uuid/${uuidByHostname.${hostname} or ""}";
        fsType = "ntfs3";
        options = [
          "nofail"
          "noatime"
          "uid=1000"
          "gid=${toString config.users.groups.users.gid}"
          "umask=022"
          "windows_names"
        ];
      };
    };
}
