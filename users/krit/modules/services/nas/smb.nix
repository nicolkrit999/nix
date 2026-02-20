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

  nixos.ifEnabled =
    {
      cfg,
      constants,
      ...
    }:
    let
      nasIP = "100.101.189.91";
      # Comm-5. NAS credentials
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

      mountShare =
        shareName:
        let
          localName = builtins.replaceStrings [ " " ] [ "_" ] shareName;
        in
        {
          name = "/mnt/nicol_nas/smb/krit/${localName}";
          value = {
            device = "//${nasIP}/${shareName}";
            fsType = "cifs";
            options = [
              "credentials=${credentialsFile}"
              "file_mode=0777"
              "dir_mode=0777"
              "nounix"
              "forceuid"
              "forcegid"
              "uid=${toString config.users.users.${constants.user}.uid}"
              "gid=${toString config.users.groups.users.gid}"

              # Performance optimizations
              "fsc" # Enable local disk caching (Requires cachefilesd below)
              "actimeo=60" # Cache file attributes for 60s (Critical for Terminal FMs)
              "noatime" # Don't update access times on server
              "vers=3.1.1" # Force modern SMB protocol (safer/faster than negotiating)
              "soft"

              # Safety flags
              "nofail" # Prevents boot failure if NAS is unreachable
              "_netdev" # Tells systemd this is a network device
              "noauto"
              "x-systemd.automount" # Creates the mount unit systemd expects

            ];
          };
        };
    in
    {
      environment.systemPackages = [ pkgs.cifs-utils ];
      services.cachefilesd.enable = true;

      fileSystems = builtins.listToAttrs (map mountShare shares);

      # Enable Tailscale so we can reach the NAS
      services.tailscale.enable = lib.mkForce true;

      sops.secrets.nas-krit-credentials = {
        sopsFile = ../../../../../common/krit/sops/krit-common-secrets-sops.yaml;
      };

      # ---------------------------------------------------------
      # SMB Cache Warmer
      # ---------------------------------------------------------
      # It add to much overhead and slow down dolphin opening times
      /*
        systemd.services.smb-warmer = {
          description = "Warm up SMB Share caches";
          # Ensure we wait for Tailscale, otherwise this will fail
          after = [
            "network-online.target"
            "tailscale.service"
          ];
          wants = [ "network-online.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "simple";
            Nice = 19;
            CPUSchedulingPolicy = "idle";
            IOSchedulingClass = "idle";
          };

          script =
            let
              mkPath = name: "/mnt/nicol_nas/smb/krit/${builtins.replaceStrings [ " " ] [ "_" ] name}";
              scanCommands = map (
                share: "${pkgs.fd}/bin/fd . '${mkPath share}' --max-depth 3 --type d --threads 1"
              ) shares;
            in
            ''
              # Wait a moment for connection stability
              sleep 10

              echo "Starting SMB Warmup..."
              ${builtins.concatStringsSep "\n" scanCommands}
              echo "SMB Warmup complete."
            '';
        };
      */
    };
}
