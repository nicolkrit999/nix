{
  config,
  pkgs,
  vars,
  lib,
  ...
}:

let
  nasUser = "krit";
  nasHost = "100.101.189.91"; # Tailscale IP

  mountVol1 = "/mnt/nicol_nas/ssh/krit/volume1";
  mountVol2 = "/mnt/nicol_nas/ssh/krit/volume2";

  # Comm-2. Shared private key to ssh into the nas
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
    "reconnect"
    "ServerAliveInterval=15"
    "StrictHostKeyChecking=accept-new"
  ];
in
{
  environment.systemPackages = [ pkgs.sshfs ];
  services.tailscale.enable = lib.mkForce true;

  # ---------------------------------------------------------
  # 🔐 SOPS: NAS SSH Key (Comm-2)
  # ---------------------------------------------------------
  sops.secrets.nas_ssh_key = {
    sopsFile = ../../../../../common/secrets.yaml;
  };

  fileSystems."${mountVol1}" = {
    device = "${nasUser}@${nasHost}:/volume1";
    fsType = "fuse.sshfs";
    options = commonOptions;
  };

  fileSystems."${mountVol2}" = {
    device = "${nasUser}@${nasHost}:/volume2";
    fsType = "fuse.sshfs";
    options = commonOptions;
  };
}
