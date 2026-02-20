{
  delib,
  config,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "krit.services.nas.sshfs";
  options.krit.services.nas.sshfs = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      nasUser = "root";
      nasHost = "100.101.189.91"; # Tailscale IP

      mountPoint = "/mnt/nicol_nas/ssh/system_root";

      # Comm-2.
      # Shared private key to ssh into the nas
      identityFile = config.sops.secrets.nas_ssh_key.path;

      commonOptions = [
        "nofail"
        "_netdev"
        "noauto"
        "x-systemd.automount"
        "allow_other"
        "IdentityFile=${identityFile}"
        "uid=1000"
        "gid=100"
        "umask=022"
        "idmap=user"
        "reconnect"
        "ServerAliveInterval=15"
        "StrictHostKeyChecking=accept-new"
        "Compression=yes"
      ];
    in
    {
      environment.systemPackages = [ pkgs.sshfs ];
      services.tailscale.enable = lib.mkForce true;
      systemd.tmpfiles.rules = [ "d ${mountPoint} 0755 krit users -" ];

      # ---------------------------------------------------------
      # 🔐 SOPS: NAS SSH Key (Comm-2)
      # ---------------------------------------------------------
      sops.secrets.nas_ssh_key = {
        sopsFile = ../../../sops/krit-common-secrets-sops.yaml;
      };

      # ---------------------------------------------------------
      # 💾 SINGLE ROOT MOUNT
      # ---------------------------------------------------------
      fileSystems."${mountPoint}" = {
        device = "${nasUser}@${nasHost}:/";
        fsType = "fuse.sshfs";
        options = commonOptions;
      };
    };
}
