{ config, pkgs, ... }:

let
  nasIP = "100.101.189.91";

  # List of SMB shares to mount from the NAS
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
      name = "/mnt/nicol-nas/${localName}";
      value = {
        device = "//${nasIP}/${shareName}";
        fsType = "cifs";
        options = [
          "x-systemd.automount"
          "noauto"
          "credentials=/etc/nixos/secrets/nicol-nas-smb-secrets"

          # Permissions: 0777 means "Everyone can write"
          # Needed otherwise Krit cannot write to the share
          "file_mode=0777"
          "dir_mode=0777"

          # Force client-side permission handling
          "nounix"
          "forceuid"
          "forcegid"
          "uid=${toString config.users.users.krit.uid}"
          "gid=${toString config.users.groups.users.gid}"

          "nofail"
        ];
      };
    };

in
{
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems = builtins.listToAttrs (map mountShare shares);
}
