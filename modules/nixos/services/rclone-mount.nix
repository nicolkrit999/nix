{ delib, pkgs, lib, ... }:
delib.module {
  name = "services.rcloneMount";

  options = with delib; moduleOptions {
    enable = boolOption false;
    mounts = listOfOption
      (submodule {
        options = {
          name = strOption "";
          remote = strOption "";
          configFile = strOption "";
          mountPoint = strOption "";
          vfsCacheMode = strOption "full";
        };
      })
      [ ];
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      user = myconfig.constants.user;
      mkService = m: {
        name = "rclone-mount-${m.name}";
        value = {
          Unit = {
            Description = "Mount ${m.name} via rclone";
            After = [ "network-online.target" ];
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "notify";
            ExecStart = "${pkgs.rclone}/bin/rclone mount --config ${m.configFile} ${m.remote} ${m.mountPoint} --vfs-cache-mode ${m.vfsCacheMode} --vfs-cache-max-size 10G --dir-cache-time 48h";
            ExecStop = "/run/wrappers/bin/fusermount -u ${m.mountPoint}";
            Restart = "on-failure";
            RestartSec = "10s";
            Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
          };
        };
      };
    in
    lib.mkIf (cfg.mounts != [ ]) {
      systemd.tmpfiles.rules = map (m: "d ${m.mountPoint} 0755 ${user} users -") cfg.mounts;
      home-manager.users.${user} = {
        home.packages = [ pkgs.rclone ];
        systemd.user.services = builtins.listToAttrs (map mkService cfg.mounts);
      };
    };
}
