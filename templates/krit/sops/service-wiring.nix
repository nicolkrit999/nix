# Wires krit sops secrets to services (davfs2 secrets template for the opencloud mount, tailscale auth key).
# Imported by hosts/nixos-{desktop,laptop}/system.nix; needs myconfig.krit.commonSopsSecrets enabled (declares nas_opencloud_user/pass and tailscale_key).
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

  # The sshfs/smb/borg modules declare their own secrets and set their own path options.
  myconfig.krit.services.nas.opencloud-mount.secretsFile = config.sops.templates."davfs-secrets".path;

  # Wire tailscale auth key
  services.tailscale.authKeyFile = config.sops.secrets.tailscale_key.path;
}
