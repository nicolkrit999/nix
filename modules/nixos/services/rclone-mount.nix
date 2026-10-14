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
      names = map (m: m.name) cfg.mounts;
      stateConfig = m: "%S/rclone-mount/${m.name}.conf";
      # Re-encrypting the sops secret has no effect until this copy is deleted.
      seedConfig = pkgs.writeShellScript "rclone-seed-config" ''
        [ -e "$1" ] || ${pkgs.coreutils}/bin/install -D -m 600 "$2" "$1"
      '';
      mkService = m: {
        name = "rclone-mount-${m.name}";
        value = {
          Unit = {
            Description = "Mount ${m.name} via rclone";
          };
          Install.WantedBy = [ "default.target" ];
          Service = {
            Type = "notify";
            ExecStartPre = "${seedConfig} ${stateConfig m} ${m.configFile}";
            ExecStart = "${lib.getExe pkgs.rclone} mount --config ${stateConfig m} ${m.remote} ${m.mountPoint} --vfs-cache-mode ${m.vfsCacheMode} --vfs-cache-max-size 10G --dir-cache-time 48h";
            ExecStop = "/run/wrappers/bin/fusermount -u ${m.mountPoint}";
            Restart = "on-failure";
            RestartSec = "10s";
            # systemd never expands $PATH, so the full list is spelled out
            Environment = [ "PATH=${lib.makeBinPath [ pkgs.rclone pkgs.coreutils ]}:/run/wrappers/bin" ];
          };
        };
      };
    in
    lib.mkIf (cfg.mounts != [ ]) {
      assertions = [
        {
          assertion = lib.all (m: m.name != "" && m.remote != "" && m.configFile != "" && m.mountPoint != "") cfg.mounts;
          message = "services.rcloneMount.mounts: every mount needs a non-empty name, remote, configFile and mountPoint.";
        }
        {
          assertion = lib.length (lib.unique names) == lib.length names;
          message = "services.rcloneMount.mounts: mount names must be unique, got ${builtins.toJSON names}.";
        }
      ];
      systemd.tmpfiles.rules = map (m: "d ${m.mountPoint} 0755 ${user} users -") cfg.mounts;
      home-manager.users.${user} = {
        home.packages = [ pkgs.rclone ];
        systemd.user.services = builtins.listToAttrs (map mkService cfg.mounts);
      };
    };
}
