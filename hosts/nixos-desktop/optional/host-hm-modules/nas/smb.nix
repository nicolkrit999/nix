{
  config,
  pkgs,
  vars,
  lib,
  ...
}:

let
  nasIP = "100.101.189.91";
  credentialsFile = config.sops.secrets.nas-smb-secrets.path;

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
      name = "/mnt/nicol-nas/${localName}";
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
          "uid=${toString config.users.users.${vars.user}.uid}"
          "gid=${toString config.users.groups.users.gid}"

          "noauto" # Do NOT mount at boot or rebuild
          "x-systemd.automount" # Mount ONLY when I access the folder
          "x-systemd.idle-timeout=3600" # Disconnect after 1 hour of inactivity
          "x-systemd.mount-timeout=1s" # Kill unmount after 1 seconds if stuck
          "soft" # mount prevents Kernel hangs on network loss

          # Safety flags
          "nofail"
          "_netdev" # Tells systemd this is a network device
        ];
      };
    };
in
{
  environment.systemPackages = [ pkgs.cifs-utils ];

  fileSystems = builtins.listToAttrs (map mountShare shares);

  # Enable Tailscale so we can reach the NAS
  services.tailscale.enable = lib.mkForce true;

  sops.secrets.nas-smb-secrets = { };
}
