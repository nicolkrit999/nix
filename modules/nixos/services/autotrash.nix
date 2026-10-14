{ delib, config, lib, pkgs, ... }:
delib.module {
  name = "services.autotrash";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      retentionDays = intOption 30;
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      user = myconfig.constants.user;
    in
    {
      environment.systemPackages = [ pkgs.autotrash ];

      systemd.services.cleanup-trash = {
        description = "Clean up trash older than ${toString cfg.retentionDays} days";
        serviceConfig = {
          Type = "oneshot";
          User = user;
          Environment = "HOME=${config.users.users.${user}.home}";
          ExecStart = "${lib.getExe pkgs.autotrash} -d ${toString cfg.retentionDays}";
        };
      };

      systemd.timers.cleanup-trash = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
}
