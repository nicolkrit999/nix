{ delib, pkgs, ... }:
delib.module {
  name = "krit.system.autotrash";


  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      retentionDays = intOption 30;
    };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    {
      environment.systemPackages = [ pkgs.autotrash ];

      systemd.services.cleanup_trash = {
        description = "Clean up trash older than ${toString cfg.retentionDays} days";
        serviceConfig = {
          Type = "oneshot";
          User = myconfig.constants.user;
          Environment = "HOME=/home/${myconfig.constants.user}";
          ExecStart = "${pkgs.autotrash}/bin/autotrash -d ${toString cfg.retentionDays}";
        };
      };

      systemd.timers.cleanup_trash = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };
    };
}
