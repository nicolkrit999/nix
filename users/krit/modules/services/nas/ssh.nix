{
  delib,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "krit.services.nas.sshfs";
  options.krit.services.nas.sshfs = with delib; {
    enable = boolOption false;
    identityFile = strOption ""; # 🌟 Receiver Option
  };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      nasUser = "root";
      nasHost = "100.101.189.91";
      mountPoint = "/mnt/nicol_nas/ssh/system_root";
    in
    {
      environment.systemPackages = [ pkgs.sshfs ];
      services.tailscale.enable = lib.mkForce true;
      systemd.tmpfiles.rules = [ "d ${mountPoint} 0755 krit users -" ];

      fileSystems."${mountPoint}" = {
        device = "${nasUser}@${nasHost}:/";
        fsType = "fuse.sshfs";
        options = [
          "nofail"
          "_netdev"
          "noauto"
          "x-systemd.automount"
          "allow_other"
          "IdentityFile=${cfg.identityFile}" # 🌟 Read from Option
          "uid=1000"
          "gid=100"
          "umask=022"
          "idmap=user"
          "reconnect"
          "ServerAliveInterval=15"
          "StrictHostKeyChecking=accept-new"
          "Compression=yes"
        ];
      };
    };
}
