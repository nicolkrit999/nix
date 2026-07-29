{ delib, config, ... }:
delib.module {
  name = "krit.services.cloud.protonDrive";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    sops.secrets.rclone_protondrive_conf = {
      sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
      owner = myconfig.constants.user;
    };
    myconfig.services.rcloneMount.mounts = [{
      name = "proton-drive";
      remote = "protondrive:";
      configFile = config.sops.secrets.rclone_protondrive_conf.path;
      mountPoint = "/mnt/protondrive";
    }];
  };
}
