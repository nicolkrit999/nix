{ delib
, lib
, config
, ...
}:
delib.module {
  name = "krit.services.nas.opencloud-mount";
  options = with delib; moduleOptions {
    enable = boolOption false;
    secretsFile = strOption "";
    spaces = listOfOption attrs [
      {
        path = "Personal";
        url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$e644ca2a-2f80-4b31-89f0-6c848de661cc/";
      }
      {
        path = "University/0001-General";
        url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$f5684f49-3aad-4268-bfc5-e00a26401c9f";
      }
      {
        path = "University/0002-Supsi";
        url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$cce01961-8714-4f83-a44a-0b9af5b06ffa";
      }
      {
        path = "University/0003-Usi";
        url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$bbcb3f1c-eb07-4379-b2f6-39bae25f1f31";
      }
    ];
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      mountPoint = "/mnt/nicol_nas/webdav/opencloud";
      uid = toString config.users.users.${myconfig.constants.user}.uid;
      gid = toString config.users.groups.users.gid;

      mkOpencloudFileSystem = space: {
        name = "${mountPoint}/${space.path}";
        value = {
          device = space.url;
          fsType = "davfs";
          options = [
            "uid=${uid}"
            "gid=${gid}"
            "file_mode=0664"
            "dir_mode=0775"
            "_netdev"
            "nofail"
            "noauto"
            "x-systemd.automount"
          ];
        };
      };
    in
    {
      services.davfs2.enable = true;
      services.davfs2.settings.globalSection = {
        use_locks = "0";
        gui_optimize = "1";
      };

      environment.etc."davfs2/secrets".source = cfg.secretsFile;

      fileSystems = lib.listToAttrs (map mkOpencloudFileSystem cfg.spaces);

      services.tailscale.enable = lib.mkForce true;
      users.users.${myconfig.constants.user}.extraGroups = [ "davfs2" ];
      systemd.tmpfiles.rules = [
        "d /mnt/nicol_nas 0700 ${myconfig.constants.user} users -"
        "d ${mountPoint}/University 0700 ${myconfig.constants.user} users -"
      ];
    };
}
