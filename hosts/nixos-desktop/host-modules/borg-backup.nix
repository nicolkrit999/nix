{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ---------------------------------------------------------
  # 🔧 VARIABLES
  # ---------------------------------------------------------
  nasUser = "krit";
  nasHost = "nicol-nas"; # Tailscale MagicDNS
  nasPath = "/volume1/Default-volume-1/0001_Docker/borgitory/${config.networking.hostName}";

  sshKeyPath = config.sops.secrets.borg-private-key.path;
  passphraseFile = config.sops.secrets.borg-passphrase.path;
in
{
  services.borgmatic = {
    enable = true;

    configurations = {
      "desktop-data" = {

        # 1. Sources & Destinations
        source_directories = [ "/home/krit" ];

        repositories = [
          {
            path = "ssh://${nasUser}@${nasHost}${nasPath}";
            label = "nas-repo";
          }
        ];

        # 2. Exclusions
        exclude_patterns = [
          # -------------------------------------------------------------------
          # 1. THE "ELECTRON KILLER" (Smart Generic Rules)
          # -------------------------------------------------------------------
          # Catches junk from Discord, Obsidian, VSCode, Slack, Element, etc.
          # automatically, so you don't have to list them one by one.
          "*/Code Cache"
          "*/GPUCache"
          "*/DawnWebGPUCache"
          "*/DawnGraphiteCache"
          "*/Session Storage"
          "*/blob_storage"
          "*/PersistentCache" # Common in Spotify/Media apps

          # -------------------------------------------------------------------
          # 2. NOISY FILE EXTENSIONS
          # -------------------------------------------------------------------
          "*.log"
          "*.tmp"
          "*.bak"
          "*.sock"
          "*.vdi" # VirtualBox Disks
          "*.qcow2" # QEMU Disks
          "*.iso" # Disk Images

          # -------------------------------------------------------------------
          # 3. HEAVY STANDARD DIRECTORIES
          # -------------------------------------------------------------------
          "/home/*/Downloads"
          "/home/*/.local/share/Trash"
          "/home/*/.local/share/recent-documents"
          "/home/*/.cache" # The standard Linux cache folder
          "/home/*/.local/state" # Often contains logs/history
          "/home/*/.local/share/baloo" # KDE File Indexer (huge)

          # -------------------------------------------------------------------
          # 4. BROWSERS (Synced/Heavy)
          # -------------------------------------------------------------------
          # These are too big and usually sync via cloud accounts anyway.
          "/home/*/.mozilla"
          "/home/*/.config/google-chrome"
          "/home/*/.config/chromium"
          "/home/*/.config/BraveSoftware"

          # -------------------------------------------------------------------
          # 5. DEVELOPER TOOLS & LANGUAGES
          # -------------------------------------------------------------------
          "/home/*/.cargo"
          "/home/*/.npm"
          "/home/*/.m2" # Java Maven
          "/home/*/.gradle"
          "/home/*/.dotnet"
          "/home/*/.p2" # Eclipse
          "/home/*/.vscode" # Extensions are re-downloadable
          "/home/*/.config/Code"
          "/home/*/.config/Cursor"
          "/home/*/.var/app/*/cache" # Flatpak caches

          # -------------------------------------------------------------------
          # 6. SPECIFIC APP CLUTTER
          # -------------------------------------------------------------------
          # Things that don't fit the generic rules perfectly
          "/home/*/.local/share/TelegramDesktop/tdata/emoji"
          "/home/*/.local/share/TelegramDesktop/tdata/temp"
          "/home/*/.local/share/Zeal" # Offline doc sets (re-downloadable)
          "/home/*/.local/share/nvim"
          "/home/*/.config/libreoffice/*/cache"
          "/home/*/.config/yazi/*"
          "/home/*/.config/sops/*"

          # -------------------------------------------------------------------
          # 7. YOUR PERSONAL SYNCED FOLDERS
          # -------------------------------------------------------------------
          # Assuming these are backed up via Git or Syncthing already
          "/home/*/developing-projects"
          "/home/*/dotfiles"
          "/home/*/nixOS"
          "/home/*/progettoFDI"
          "/home/*/tools"
          "/home/*/obese_dinosaurs"

          # -------------------------------------------------------------------
          # 8. OTHER
          # -------------------------------------------------------------------
          "/home/*/etc/nixos/secrets" # Sensitive data (handled separately)
        ];

        # 3. Storage & Encryption
        encryption_passcommand = "cat ${passphraseFile}";
        compression = "auto,zstd";
        ssh_command = "ssh -i ${sshKeyPath} -o StrictHostKeyChecking=no";

        # 4. Retention (Keep Policy)
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;

        # 5. Consistency Checks
        checks = [
          { name = "repository"; }
          { name = "archives"; }
        ];
        check_last = 3;
      };
    };
  };

  # Run daily at 18:00, or immediately if computer was off
  systemd.timers.borgmatic = {
    timerConfig = {
      OnCalendar = "18:00";
      Persistent = true;
      RandomizedDelaySec = "5m";
    };
  };

  # Enable Tailscale so we can reach the NAS
  services.tailscale.enable = true;
}
