# Wires sops secrets to krit services
# Import this in host system.nix imports block (after sops module)
{ config, ... }:
{
  # davfs-secrets template for owncloud
  sops.templates."davfs-secrets" = {
    content = ''
      ${config.sops.placeholder.nas_owncloud_url} ${config.sops.placeholder.nas_owncloud_user} ${config.sops.placeholder.nas_owncloud_pass}
    '';
    owner = "root";
    group = "root";
    mode = "0600";
  };

  # Wire sops secrets to NAS services
  myconfig.krit.services.nas.sshfs.identityFile = config.sops.secrets.nas_ssh_key.path;
  myconfig.krit.services.nas.smb.credentialsFile = config.sops.secrets.nas-krit-credentials.path;
  myconfig.krit.services.nas.desktop-borg-backup.passphraseFile = config.sops.secrets.borg-passphrase.path;
  myconfig.krit.services.nas.desktop-borg-backup.sshKeyPath = config.sops.secrets.borg-private-key.path;
  myconfig.krit.services.nas.owncloud.secretsFile = config.sops.templates."davfs-secrets".path;

  # Wire tailscale auth key
  services.tailscale.authKeyFile = config.sops.secrets.tailscale_key.path;
}
