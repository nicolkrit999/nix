# Wires sops secrets to krit services
# Import this in host system.nix imports block (after sops module)
{ config, lib, ... }:
{
  # davfs-secrets template for opencloud: one "<url> <user> <pass>" line per
  # space, same account for all of them (see krit.services.nas.opencloud-mount.spaces)
  sops.templates."davfs-secrets" = {
    content = lib.concatMapStringsSep "\n"
      (space: ''${space.url} "${config.sops.placeholder.nas_opencloud_user}" "${config.sops.placeholder.nas_opencloud_pass}"'')
      config.myconfig.krit.services.nas.opencloud-mount.spaces;
    owner = "root";
    group = "root";
    mode = "0600";
  };

  # Wire sops secrets to NAS services
  myconfig.krit.services.nas.sshfs.identityFile = config.sops.secrets.nas_ssh_key.path;
  myconfig.krit.services.nas.smb.credentialsFile = config.sops.secrets.nas-krit-credentials.path;
  myconfig.krit.services.nas.desktop-borg-backup.passphraseFile = config.sops.secrets.borg-passphrase.path;
  myconfig.krit.services.nas.desktop-borg-backup.sshKeyPath = config.sops.secrets.borg-private-key.path;
  myconfig.krit.services.nas.laptop-borg-backup.passphraseFile = config.sops.secrets.borg-passphrase.path;
  myconfig.krit.services.nas.laptop-borg-backup.sshKeyPath = config.sops.secrets.borg-private-key.path;
  myconfig.krit.services.nas.opencloud-mount.secretsFile = config.sops.templates."davfs-secrets".path;

  # Wire tailscale auth key
  services.tailscale.authKeyFile = config.sops.secrets.tailscale_key.path;
}
