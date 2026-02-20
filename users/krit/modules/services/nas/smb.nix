{
  delib,
  pkgs,
  lib,
  config,
  ...
}:
delib.module {
  name = "krit.services.nas.smb";
  options.krit.services.nas.smb = with delib; {
    enable = boolOption false;
    credentialsFile = strOption ""; # 🌟 Receiver Option
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      nasIP = "100.101.189.91";
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
              "credentials=${cfg.credentialsFile}" # 🌟 Read from Option
              "file_mode=0777"
              "dir_mode=0777"
              "nounix"
              "forceuid"
              "forcegid"
              "uid=${toString config.users.users.${myconfig.constants.user}.uid}"
              "gid=${toString config.users.groups.users.gid}"
              "fsc"
              "actimeo=60"
              "noatime"
              "vers=3.1.1"
              "soft"
              "nofail"
              "_netdev"
              "noauto"
              "x-systemd.automount"
            ];
          };
        };
    in
    {
      environment.systemPackages = [ pkgs.cifs-utils ];
      services.cachefilesd.enable = true;
      fileSystems = builtins.listToAttrs (map mountShare shares);
      services.tailscale.enable = lib.mkForce true;
    };
}
