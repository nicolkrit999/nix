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
      hasImpermanence = myconfig.services.impermanence.enable or false;
      rootSubvolume = if hasImpermanence then "/persist" else "/";
      rootSnapshotsDir = if hasImpermanence then "/persist/.snapshots" else "/.snapshots";
      rootConfigName = if hasImpermanence then "persist" else "root";
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
          ${rootConfigName} = {
            SUBVOLUME = rootSubvolume;
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

          # Setup for ${rootSubvolume}
          if [ ! -e ${rootSnapshotsDir} ]; then
            echo "Creating ${rootSnapshotsDir} subvolume..."
            ${pkgs.btrfs-progs}/bin/btrfs subvolume create ${rootSnapshotsDir}
          fi
        '';
      };
    };
}
