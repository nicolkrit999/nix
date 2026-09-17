{ delib, config, lib, pkgs, ... }:
delib.module {
  name = "krit.services.nas.opencloud";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user or "krit";
      mountRoot = "/Volumes/nicol_nas/webdav/opencloud";

      spaces = [
        {
          name = "personal";
          path = "Personal";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$e644ca2a-2f80-4b31-89f0-6c848de661cc/";
        }
        {
          name = "uni_general";
          path = "University/0001-General";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$f5684f49-3aad-4268-bfc5-e00a26401c9f";
        }
        {
          name = "uni_supsi";
          path = "University/0002-Supsi";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$cce01961-8714-4f83-a44a-0b9af5b06ffa";
        }
        {
          name = "uni_usi";
          path = "University/0003-Usi";
          url = "https://opencloud.nicolkrit.ch/dav/spaces/5949981c-11e0-455e-8d64-7671a8b8f26a$bbcb3f1c-eb07-4379-b2f6-39bae25f1f31";
        }
      ];

      mkOpencloudAgent = space:
        let
          remoteName = "nas_opencloud_${space.name}";
          remoteEnvPrefix = "RCLONE_CONFIG_${lib.toUpper remoteName}";
          mountPoint = "${mountRoot}/${space.path}";
        in
        {
          name = "opencloud-rclone-${space.name}";
          value = {
            serviceConfig = {
              Label = "com.krit.opencloud-rclone-${space.name}";
              RunAtLoad = true;
              KeepAlive = true;
              StandardOutPath = "/Users/${user}/Library/Logs/rclone-opencloud-${space.name}.log";
              StandardErrorPath = "/Users/${user}/Library/Logs/rclone-opencloud-${space.name}.err";
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
              OC_USER=$(cat ${config.sops.secrets.nas_opencloud_user.path})
              OC_PASS=$(cat ${config.sops.secrets.nas_opencloud_pass.path})

              # 2. Obscure password for rclone config (required by rclone)
              OC_PASS_OBSCURED=$(rclone obscure "$OC_PASS")

              # 3. Create Config
              export ${remoteEnvPrefix}_TYPE=webdav
              export ${remoteEnvPrefix}_URL="${space.url}"
              # NOTE: OpenCloud is an ownCloud-protocol-compatible fork; rclone has no
              # dedicated "opencloud" webdav vendor, so we keep vendor=owncloud (this
              # refers to the WebDAV dialect rclone speaks, not the old service name).
              export ${remoteEnvPrefix}_VENDOR=owncloud
              export ${remoteEnvPrefix}_USER="$OC_USER"
              export ${remoteEnvPrefix}_PASS="$OC_PASS_OBSCURED"

              # 4. Prepare Mount
              mkdir -p "${mountPoint}"
              umount "${mountPoint}" || true

              # 5. Mount
              # --vfs-cache-mode writes: Essential for stability
              rclone mount ${remoteName}: "${mountPoint}" \
                --vfs-cache-mode writes \
                --volname "OpenCloud ${space.name}"
            '';
          };
        };
    in
    {
      environment.systemPackages = [ pkgs.rclone ];
      services.tailscale.enable = lib.mkForce true;

      # ---------------------------------------------------------
      # 1. SOPS: Secrets (shared account across all spaces)
      # ---------------------------------------------------------
      sops.secrets = {
        nas_opencloud_user = {
          sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
          owner = user;
        };
        nas_opencloud_pass = {
          sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
          owner = user;
        };
      };

      system.activationScripts.opencloud-nas-mountpoints.text = ''
        ${lib.concatMapStringsSep "\n" (space: "mkdir -p \"${mountRoot}/${space.path}\"") spaces}
        chown -R ${user} /Volumes/nicol_nas
      '';

      launchd.user.agents = lib.listToAttrs (map mkOpencloudAgent spaces);
    };
}
