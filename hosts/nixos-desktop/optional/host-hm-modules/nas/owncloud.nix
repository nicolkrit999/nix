{ config
, lib
, pkgs
, vars
, ...
}:

let
  mountPoint = "/mnt/nicol_nas/webdav/owncloud";
in
{
  # Enables the service, creating the necessary 'davfs2' group and user
  services.davfs2.enable = true;

  services.davfs2.settings = {
    globalSection = {
      use_locks = "0";
      gui_optimize = "1";
    };
  };
  # ---------------------------------------------------------
  # 1. Prepare the Secret for DAVFS2
  # ---------------------------------------------------------
  # Comm-6. NAS owncloud webdav remote connection
  sops.templates."davfs-secrets" = {
    content = ''
      ${config.sops.placeholder.nas_owncloud_url} ${config.sops.placeholder.nas_owncloud_user} ${config.sops.placeholder.nas_owncloud_pass}
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

  # Enable Tailscale so we can reach the NAS
  services.tailscale.enable = lib.mkForce true;

  # ---------------------------------------------------------
  # 4. Sops Secrets Definition
  # ---------------------------------------------------------
  sops.secrets = {
    nas_owncloud_user.sopsFile = ../../../../../common/secrets.yaml;
    nas_owncloud_pass.sopsFile = ../../../../../common/secrets.yaml;
    nas_owncloud_url.sopsFile = ../../../../../common/secrets.yaml;
  };

  users.users.${vars.user}.extraGroups = [ "davfs2" ];
  systemd.services.owncloud-warmer = {
    description = "Warm up OwnCloud mount cache";
    after = [
      "network-online.target"
      "tailscale.service"
    ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      Nice = 19;
      CPUSchedulingPolicy = "idle";
      IOSchedulingClass = "idle";

      ExecStart = "${pkgs.fd}/bin/fd . ${mountPoint} --max-depth 7 --type d --threads 1";
    };
  };
}
