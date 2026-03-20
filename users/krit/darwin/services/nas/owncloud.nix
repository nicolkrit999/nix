{ delib, config, lib, pkgs, ... }:
delib.module {
  name = "krit.services.nas.owncloud";

  options.krit.services.nas.owncloud = with delib; {
    enable = boolOption false;
  };

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user or "krit";
      mountPoint = "/Volumes/nicol_nas/webdav/owncloud";

      # Rclone Config Name
      remoteName = "nas_owncloud";
    in
    {
      environment.systemPackages = [ pkgs.rclone ];
      services.tailscale.enable = lib.mkForce true;

      # ---------------------------------------------------------
      # 1. SOPS: Secrets
      # ---------------------------------------------------------
      sops.secrets = {
        nas_owncloud_user = {
          sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
          owner = user;
        };
        nas_owncloud_pass = {
          sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
          owner = user;
        };
        nas_owncloud_url = {
          sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
          owner = user;
        };
      };

      # Pre-create mount directory as root (user agents can't mkdir in /Volumes)
      system.activationScripts.owncloud-nas-mountpoints.text = ''
        mkdir -p /Volumes/nicol_nas/webdav/owncloud
        chown -R ${user} /Volumes/nicol_nas
      '';

      launchd.user.agents.owncloud-rclone = {
        serviceConfig = {
          Label = "com.krit.owncloud-rclone";
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/Users/${user}/Library/Logs/rclone-owncloud.log";
          StandardErrorPath = "/Users/${user}/Library/Logs/rclone-owncloud.err";
          EnvironmentVariables = {
            PATH = "${
              lib.makeBinPath [
                pkgs.rclone
                pkgs.coreutils
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };

        script = ''
          # 1. Read Secrets
          OC_USER=$(cat ${config.sops.secrets.nas_owncloud_user.path})
          OC_PASS=$(cat ${config.sops.secrets.nas_owncloud_pass.path})
          OC_URL=$(cat ${config.sops.secrets.nas_owncloud_url.path})

          # 2. Obscure password for rclone config (required by rclone)
          OC_PASS_OBSCURED=$(rclone obscure "$OC_PASS")

          # 3. Create Config
          export RCLONE_CONFIG_NAS_OWNCLOUD_TYPE=webdav
          export RCLONE_CONFIG_NAS_OWNCLOUD_URL="$OC_URL"
          export RCLONE_CONFIG_NAS_OWNCLOUD_VENDOR=owncloud
          export RCLONE_CONFIG_NAS_OWNCLOUD_USER="$OC_USER"
          export RCLONE_CONFIG_NAS_OWNCLOUD_PASS="$OC_PASS_OBSCURED"

          # 4. Prepare Mount
          mkdir -p "${mountPoint}"
          umount "${mountPoint}" || true

          # 5. Mount
          # --vfs-cache-mode writes: Essential for stability
          rclone mount ${remoteName}: "${mountPoint}" \
            --vfs-cache-mode writes \
            --volname "OwnCloud"
        '';
      };
    };
}
