{
  delib,
  config,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "krit.services.nas.smb";

  options.krit.services.nas.smb = with delib; {
    enable = boolOption false;
  };

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      user = myconfig.constants.user or "krit";
      nasIP = "100.101.189.91";
      # NAS credentials
      credentialsFile = config.sops.secrets.nas-krit-credentials.path;

      # List of SMB shares
      shares = [
        "Amministrazione-NAS"
        "Default-volume-1"
        "Default-volume-2"
        "docker"
        "Famiglia"
        "Krit SD 512"
        "Momentary-volume-1"
        "personal_folder"
      ];

      mountBase = "/Volumes/nicol_nas/smb";

      mountScript = ''
        # 1. Load Credentials (parse standard smb credentials file)
        # Expects format: username=x \n password=y
        if [ -f "${credentialsFile}" ]; then
          source "${credentialsFile}"
        else
          echo "Credentials file not found!"
          exit 1
        fi

        # 2. Function to mount
        do_mount() {
          SHARE=$1
          MOUNTPOINT="${mountBase}/$SHARE"

          mkdir -p "$MOUNTPOINT"

          # Check if already mounted
          if ! mount | grep -q "$MOUNTPOINT"; then
            echo "Mounting $SHARE..."
            # Use native mount_smbfs.
            # WARNING: Putting pass in URL is visible in process list, but simplest for automation without Keychain.
            mount_smbfs "//''${username}:''${password}@${nasIP}/$SHARE" "$MOUNTPOINT"
          fi
        }

        # 3. Mount all shares
        ${builtins.concatStringsSep "\n" (map (s: ''do_mount "${s}"'') shares)}
      '';

    in
    {
      services.tailscale.enable = lib.mkForce true;

      sops.secrets.nas-krit-credentials = {
        sopsFile = ../../../common/sops/krit-common-secrets-sops.yaml;
        owner = user;
      };

      # /Volumes is root:wheel 755 — user launchd agents can't mkdir there.
      # Pre-create the mount base as root so the agent script succeeds.
      system.activationScripts.smb-nas-mountpoints.text = ''
        mkdir -p /Volumes/nicol_nas/smb
        chown -R ${user} /Volumes/nicol_nas
      '';

      launchd.user.agents.smb-nas = {
        serviceConfig = {
          Label = "com.krit.smb-nas";
          RunAtLoad = true;
          StandardOutPath = "/Users/${user}/Library/Logs/smb-nas.log";
          StandardErrorPath = "/Users/${user}/Library/Logs/smb-nas.err";

          # Re-check mounts every 10 minutes
          StartInterval = 600;

          EnvironmentVariables = {
            PATH = "${
              lib.makeBinPath [
                pkgs.coreutils
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };

        script = mountScript;
      };
    };
}
