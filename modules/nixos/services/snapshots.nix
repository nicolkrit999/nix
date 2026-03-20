{ delib
, pkgs
, ...
}:
delib.module {
  name = "services.snapshots";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      retention = {
        hourly = strOption "24";
        daily = strOption "7";
        weekly = strOption "4";
        monthly = strOption "3";
        yearly = strOption "2";
      };
    };

  nixos.ifEnabled =
    { cfg
    , myconfig
    , ...
    }:
    let
      user = myconfig.constants.user;
    in
    {
      services.snapper = {
        snapshotInterval = "hourly";
        cleanupInterval = "1d";

        configs = {
          home = {
            SUBVOLUME = "/home";
            FSTYPE = "btrfs";
            ALLOW_USERS = [ "${user}" ];

            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;

            TIMELINE_LIMIT_HOURLY = cfg.retention.hourly;
            TIMELINE_LIMIT_DAILY = cfg.retention.daily;
            TIMELINE_LIMIT_WEEKLY = cfg.retention.weekly;
            TIMELINE_LIMIT_MONTHLY = cfg.retention.monthly;
            TIMELINE_LIMIT_YEARLY = cfg.retention.yearly;
          };
          root = {
            SUBVOLUME = "/";
            FSTYPE = "btrfs";
            ALLOW_USERS = [ "${user}" ];
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;

            TIMELINE_LIMIT_HOURLY = cfg.retention.hourly;
            TIMELINE_LIMIT_DAILY = cfg.retention.daily;
            TIMELINE_LIMIT_WEEKLY = cfg.retention.weekly;
            TIMELINE_LIMIT_MONTHLY = cfg.retention.monthly;
            TIMELINE_LIMIT_YEARLY = cfg.retention.yearly;
          };
        };
      };

      environment.systemPackages = with pkgs; [
        btrfs-assistant
        snapper-gui
      ];

      system.activationScripts.createSnapperHome = {
        text = ''
          # Setup for home (/home)
          if [ ! -e /home/.snapshots ]; then
            echo "Creating /home/.snapshots subvolume..."
            ${pkgs.btrfs-progs}/bin/btrfs subvolume create /home/.snapshots
          fi

          # Setup for root (/)
          if [ ! -e /.snapshots ]; then
            echo "Creating /.snapshots subvolume..."
            ${pkgs.btrfs-progs}/bin/btrfs subvolume create /.snapshots
          fi
        '';
      };
    };
}
