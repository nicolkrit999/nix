{
  # ⚠️ IT IS NOT ADVISED TO CHANGE THIS FILE AFTER THE INITIAL SETUP
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # ⚠️ REPLACE this with the target disk name (e.g. /dev/nvme0n1 or /dev/sda)
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
            # 1. Boot Partition (1GB, FAT32)
            boot = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            # 2. Root Partition (Btrfs)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Override existing partition

                subvolumes = {
                  # Root System (@)
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Home (@home)
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Nix Store (@nix)
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Logs (@log)
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                  # Snapshots (@snapshots)
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
