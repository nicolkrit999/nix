{ delib
, lib
, pkgs
, config
, ...
}:
delib.module {
  name = "krit.services.nas.smb";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      credentialsFile = strOption "";
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      user = myconfig.constants.user;
      group = config.users.users.${user}.group;
      shares = [
        "Amministrazione-NAS"
        "Default-volume-1"
        "Default-volume-2"
        "docker"
        "Famiglia"
        "Krit SD 512"
        "Momentary-volume-1"
        "Momentary-volume-2"
        "personal_folder"
      ];

      mountShare =
        shareName:
        let
          localName = builtins.replaceStrings [ " " ] [ "_" ] shareName;
        in
        {
          name = "${nas.mountRoot}/smb/${user}/${localName}";
          value = {
            device = "//${nas.tailnetIp}/${shareName}";
            fsType = "cifs";
            options = [
              "credentials=${cfg.credentialsFile}"
              "file_mode=0777"
              "dir_mode=0777"
              "nounix"
              "forceuid"
              "forcegid"
              "uid=${user}"
              "gid=${group}"
              "fsc"
              "actimeo=60"
              "noatime"
              "vers=3.1.1"
              "soft"
              "nofail"
              "_netdev"
              "noauto"
              "x-systemd.automount"
            ];
          };
        };
    in
    {
      assertions = [
        {
          assertion = cfg.credentialsFile != "";
          message = "krit.services.nas.smb.credentialsFile is empty: the SMB credentials secret path is required.";
        }
      ];

      sops.secrets.nas-krit-credentials.sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
      myconfig.krit.services.nas.smb.credentialsFile =
        lib.mkDefault config.sops.secrets.nas-krit-credentials.path;

      environment.systemPackages = [ pkgs.cifs-utils ];
      services.cachefilesd.enable = true;
      fileSystems = builtins.listToAttrs (map mountShare shares);
      myconfig.services.tailscale.enable = true;
      # Lock the parent - share contents stay 0777 (NAS quirk) but only
      # the configured user can traverse to them.
      systemd.tmpfiles.rules = [
        "d ${nas.mountRoot} 0700 ${user} ${group} -"
      ];

      home-manager.users.${user}.home.file."Documents/nicol-nas".source =
        config.home-manager.users.${user}.lib.file.mkOutOfStoreSymlink
          "${nas.mountRoot}/smb/${user}";
    };
}
