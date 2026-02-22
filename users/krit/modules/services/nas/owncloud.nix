{ delib
, lib
, config
, ...
}:
delib.module {
  name = "krit.services.nas.owncloud";
  options.krit.services.nas.owncloud = with delib; {
    enable = boolOption false;
    secretsFile = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      mountPoint = "/mnt/nicol_nas/webdav/owncloud";
    in
    {
      services.davfs2.enable = true;
      services.davfs2.settings.globalSection = {
        use_locks = "0";
        gui_optimize = "1";
      };

      # 🌟 Read template path from Option
      environment.etc."davfs2/secrets".source = cfg.secretsFile;

      fileSystems."${mountPoint}" = {
        device = "https://owncloud.nicolkrit.ch/remote.php/dav/files/oc_admin/";
        fsType = "davfs";
        options = [
          "uid=${toString config.users.users.${myconfig.constants.user}.uid}"
          "gid=${toString config.users.groups.users.gid}"
          "file_mode=0664"
          "dir_mode=0775"
          "_netdev"
          "nofail"
          "noauto"
          "x-systemd.automount"
        ];
      };

      services.tailscale.enable = lib.mkForce true;
      users.users.${myconfig.constants.user}.extraGroups = [ "davfs2" ];
    };
}
