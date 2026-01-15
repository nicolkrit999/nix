{
  config,
  pkgs,
  lib,
  vars,
  ...
}:
with lib;
let
  cfg = vars.snapshots or false;
  retention = {
    hourly = vars.snapshotRetention.hourly or "12";
    daily = vars.snapshotRetention.daily or "3";
    weekly = vars.snapshotRetention.weekly or "3";
    monthly = vars.snapshotRetention.monthly or "2";
    yearly = vars.snapshotRetention.yearly or "1";
  };
in
{
  config = mkIf cfg {
    services.snapper = {
      snapshotInterval = "hourly";
      cleanupInterval = "1d";

      configs = {
        home = {
          SUBVOLUME = "/home";
          FSTYPE = "btrfs";
          ALLOW_USERS = [
            "${vars.user}"
          ]; # Needed to allow the user to see root snapshots in snapper-gui

          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          TIMELINE_LIMIT_HOURLY = retention.hourly;
          TIMELINE_LIMIT_DAILY = retention.daily;
          TIMELINE_LIMIT_WEEKLY = retention.weekly;
          TIMELINE_LIMIT_MONTHLY = retention.monthly;
          TIMELINE_LIMIT_YEARLY = retention.yearly;
        };
        root = {
          SUBVOLUME = "/";
          FSTYPE = "btrfs";
          ALLOW_USERS = [ "${vars.user}" ];
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;

          TIMELINE_LIMIT_HOURLY = "6";
          TIMELINE_LIMIT_DAILY = "3";
          TIMELINE_LIMIT_WEEKLY = "3";
          TIMELINE_LIMIT_MONTHLY = "1";
          TIMELINE_LIMIT_YEARLY = "1";
        };
      };
    };

    environment.systemPackages = with pkgs; [
      btrfs-assistant
      snapper-gui
    ];

    # -----------------------------------------------------------------------
    # 🤖 AUTOMATIC SUBVOLUME CREATION
    # -----------------------------------------------------------------------
    # This script ensures /home/.snapshots exists as a real Btrfs subvolume.
    # This prevents 'nested' snapshots (snapshotting the backup folder).
    system.activationScripts.createSnapperHome = {
      text = ''
        if [ ! -e /home/.snapshots ]; then
          echo "Creating /home/.snapshots subvolume..."
          ${pkgs.btrfs-progs}/bin/btrfs subvolume create /home/.snapshots
        fi
      '';
    };

  };
}
