{ delib, config, ... }:
delib.module {
  name = "krit.services.cloud.pcloud";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    sops.secrets.rclone_pcloud_conf = {
      sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
      owner = myconfig.constants.user;
    };
    myconfig.services.rcloneMount.mounts = [{
      name = "pcloud";
      remote = "pcloud:";
      configFile = config.sops.secrets.rclone_pcloud_conf.path;
      mountPoint = "/mnt/pcloud";
    }];
  };
}
