{
  delib,
  lib,
  pkgs,
  ...
}:
delib.module {
  name = "services.snapper";
  options.services.snapper = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled =
    {
      nixos,
      ...
    }:
    let
      # Use the retention constants from your host configuration
      retention = {
        hourly = nixos.constants.snapshotRetention.hourly or "12";
        daily = nixos.constants.snapshotRetention.daily or "3";
        weekly = nixos.constants.snapshotRetention.weekly or "3";
        monthly = nixos.constants.snapshotRetention.monthly or "2";
        yearly = nixos.constants.snapshotRetention.yearly or "1";
      };

      user = nixos.constants.user; # Align with constants.nix
    in
    {
      # 🌟 Removed the extra 'config =' wrapper and 'lib.mkIf cfg'
      # because ifEnabled handles the 'cfg.enable' check for you!
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

            TIMELINE_LIMIT_HOURLY = retention.hourly;
            TIMELINE_LIMIT_DAILY = retention.daily;
            TIMELINE_LIMIT_WEEKLY = retention.weekly;
            TIMELINE_LIMIT_MONTHLY = retention.monthly;
            TIMELINE_LIMIT_YEARLY = retention.yearly;
          };
          root = {
            SUBVOLUME = "/";
            FSTYPE = "btrfs";
            ALLOW_USERS = [ "${user}" ];
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
