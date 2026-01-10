{ config, vars, ... }:

let
  mountPoint = "/mnt/owncloud";
in
{
  # Enables the service, creating the necessary 'davfs2' group and user
  services.davfs2.enable = true;

  # ---------------------------------------------------------
  # 1. Prepare the Secret for DAVFS2
  # ---------------------------------------------------------
  sops.templates."davfs-secrets" = {
    content = ''
      ${config.sops.placeholder.owncloud_url} ${config.sops.placeholder.owncloud_user} ${config.sops.placeholder.owncloud_pass}
    '';
    owner = "root";
    group = "root";
    mode = "0600";
  };

  # ---------------------------------------------------------
  # 2. Link Global Secrets
  # ---------------------------------------------------------
  environment.etc."davfs2/secrets".source = config.sops.templates."davfs-secrets".path;

  # ---------------------------------------------------------
  # 3. The FileSystem Mount
  # ---------------------------------------------------------
  fileSystems."${mountPoint}" = {
    device = "https://owncloud.nicolkrit.ch/remote.php/dav/files/oc_admin/";
    fsType = "davfs";

    options = [
      "uid=${toString config.users.users.${vars.user}.uid}"
      "gid=${toString config.users.groups.users.gid}"
      "file_mode=0664"
      "dir_mode=0775"

      "_netdev"
      "nofail"
      "noauto"
      "x-systemd.automount"
    ];
  };

  # ---------------------------------------------------------
  # 4. Sops Secrets Definition
  # ---------------------------------------------------------
  sops.secrets = {
    owncloud_user = { };
    owncloud_pass = { };
    owncloud_url = { };
  };

  users.users.${vars.user}.extraGroups = [ "davfs2" ];
}
