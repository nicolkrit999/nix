{ delib
, config
, lib
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
      snapperMounts = [ "/home" rootSubvolume ];
    in
    {
      assertions = [{
        assertion = lib.all (mp: (config.fileSystems.${mp}.fsType or "btrfs") == "btrfs") snapperMounts;
        message = "services.snapshots: snapper needs btrfs, but one of ${toString snapperMounts} is declared with another fsType.";
      }];

      services.snapper = {
        snapshotInterval = "hourly";
        cleanupInterval = "1d";

        configs =
          let
            timeline = {
              FSTYPE = "btrfs";
              TIMELINE_CREATE = true;
              TIMELINE_CLEANUP = true;
              TIMELINE_LIMIT_HOURLY = cfg.retention.hourly;
              TIMELINE_LIMIT_DAILY = cfg.retention.daily;
              TIMELINE_LIMIT_WEEKLY = cfg.retention.weekly;
              TIMELINE_LIMIT_MONTHLY = cfg.retention.monthly;
              TIMELINE_LIMIT_YEARLY = cfg.retention.yearly;
            };
          in
          {
            home = timeline // {
              SUBVOLUME = "/home";
              ALLOW_USERS = [ user ];
            };
            ${rootConfigName} = timeline // {
              SUBVOLUME = rootSubvolume;
            };
          };
      };

      environment.systemPackages = with pkgs; [
        btrfs-assistant
        snapper-gui
      ];

      system.activationScripts.createSnapperDirs = {
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
