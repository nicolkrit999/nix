{ delib, config, ... }:
delib.module {
  name = "krit.services.cloud.googleDrive";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = { myconfig, ... }: {
    sops.secrets.rclone_google_drive_conf = {
      sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
      owner = myconfig.constants.user;
    };
    myconfig.services.rcloneMount.mounts = [{
      name = "google-drive";
      remote = "gdrive:";
      configFile = config.sops.secrets.rclone_google_drive_conf.path;
      mountPoint = "/mnt/google_drive";
    }];
  };
}
