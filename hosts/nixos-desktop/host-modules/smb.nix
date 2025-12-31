{
  config,
  pkgs,
  vars,
  ...
}:

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
          # -------------------------------------------------------
          # 🔑 PERMISSIONS (avoid not being able to write)
          # -------------------------------------------------------
          "credentials=/etc/nixos/secrets/nicol-nas-smb-secrets"
          "file_mode=0777"
          "dir_mode=0777"
          "nounix"
          "forceuid"
          "forcegid"
          "uid=${toString config.users.users.${vars.user}.uid}"
          "gid=${toString config.users.groups.users.gid}"

          # -------------------------------------------------------
          # ⚡ FAST SHUTDOWN & NETWORK SAFETY
          # -------------------------------------------------------
          "nofail"
          "_netdev"
          "x-systemd.mount-timeout=5s"
          "x-systemd.device-timeout=5s"
        ];
      };
    };
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];
  fileSystems = builtins.listToAttrs (map mountShare shares);
}
