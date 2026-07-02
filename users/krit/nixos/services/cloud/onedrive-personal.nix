{ delib, config, ... }:
delib.module {
  name = "krit.services.cloud.onedrivePersonal";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    sops.secrets.rclone_onedrive_personal_conf = {
      sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
      owner = myconfig.constants.user;
    };
    myconfig.services.rcloneMount.mounts = [{
      name = "onedrive-personal";
      remote = "onedrive-personal:";
      configFile = config.sops.secrets.rclone_onedrive_personal_conf.path;
      mountPoint = "/mnt/onedrive_personal";
    }];
  };
}
