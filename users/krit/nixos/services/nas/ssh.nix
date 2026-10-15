{ delib
, lib
, config
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nas.sshfs";

  options = with delib; moduleOptions {
    enable = boolOption false;
    identityFile = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      nasUser = "root";
      user = myconfig.constants.user;
      mountPoint = "${nas.mountRoot}/ssh/system_root";
      userCfg = config.users.users.${user};
    in
    {
      assertions = [
        {
          assertion = cfg.identityFile != "";
          message = "krit.services.nas.sshfs.identityFile is empty: the NAS SSH key secret path is required.";
        }
      ];

      sops.secrets.nas_ssh_key.sopsFile = ../../../common/sops/${user}-common-secrets-sops.yaml;
      myconfig.krit.services.nas.sshfs.identityFile = lib.mkDefault config.sops.secrets.nas_ssh_key.path;

      environment.systemPackages = [ pkgs.sshfs ];
      myconfig.services.tailscale.enable = true;
      systemd.tmpfiles.rules = [
        "d ${nas.mountRoot} 0700 ${user} ${userCfg.group} -"
        "d ${mountPoint} 0755 ${user} ${userCfg.group} -"
      ];

      fileSystems."${mountPoint}" = {
        device = "${nasUser}@${nas.tailnetIp}:/";
        fsType = "fuse.sshfs";
        options = [
          "nofail"
          "_netdev"
          "noauto"
          "x-systemd.automount"
          "allow_other"
          "IdentityFile=${cfg.identityFile}"
          "uid=${toString userCfg.uid}"
          "gid=${toString config.users.groups.${userCfg.group}.gid}"
          "umask=022"
          "idmap=user"
          "reconnect"
          "ServerAliveInterval=15"
          "Compression=yes"
        ];
      };
    };
}
