{
  delib,
  lib,
  config,
  ...
}:
delib.module {
  name = "krit.services.nas.desktop-borg-backup";
  options.krit.services.nas.desktop-borg-backup = with delib; {
    enable = boolOption false;
    passphraseFile = strOption ""; # 🌟 Receiver Option
    sshKeyPath = strOption ""; # 🌟 Receiver Option
  };

  nixos.ifEnabled =
    { cfg, ... }:
    let
      nasUser = "krit";
      nasHost = "nicol-nas";
      nasPath = "/volume1/Default-volume-1/0001_Docker/borgitory/${config.networking.hostName}";
    in
    {
      services.borgmatic = {
        enable = true;
        configurations."desktop-data" = {
          source_directories = [ "/home/krit" ];
          repositories = [
            {
              path = "ssh://${nasUser}@${nasHost}${nasPath}";
              label = "nas-repo";
            }
          ];
          exclude_patterns = [
            # -------------------------------------------------------------------
            # 1. THE "ELECTRON KILLER" (Smart Generic Rules)
            # -------------------------------------------------------------------
            # Catches junk from Discord, Obsidian, VSCode, Slack, Element, etc.
            # automatically, so you don't have to list them one by one.
            "*/Code Cache" # VSCode & Electron apps
            "*/GPUCache" # Electron apps
            "*/DawnWebGPUCache" # Electron apps
            "*/Session Storage" # Electron apps
            "*/blob_storage" # Electron apps
            "*/PersistentCache" # Common in Spotify/Media apps

            # -------------------------------------------------------------------
            # 2. NOISY FILE EXTENSIONS
            # -------------------------------------------------------------------
            "*.log" # Log files
            "*.tmp" # Temporary files
            "*.bak" # Backup files
            "*.sock" # Socket files
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
            "/home/*/winboat/" # Wine Prefixes (re-create as needed)
            "/home/*/.wine/" # Wine Prefixes (re-create as needed)
            "/home/*/.local/share/Steam" # Steam games (re-downloadable)
            "/home/*/.config/whatsapp-electron" # WhatsApp cache

            # -------------------------------------------------------------------
            # 4. BROWSERS (Synced/Heavy)
            # -------------------------------------------------------------------
            # These are too big and usually sync via cloud accounts anyway.
            "/home/*/.mozilla"
            "home/*/.librewolf"
            "home/*/.librewolf-policyroot"
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
            "/home/*/.local/share/containers" # Podman/Containers cache

            # -------------------------------------------------------------------
            # 7. YOUR PERSONAL SYNCED FOLDERS
            # -------------------------------------------------------------------
            # Assuming these are backed up via Git or Syncthing already
            "/home/*/github-repos" # General repositories folder
            "/home/*/dotfiles " # Dotfiles repositories (must be in root of home to be stowed)
            "/home/*/wallpapers" # Wallpaper repo (must be in root of home to be stowed)

            # -------------------------------------------------------------------
            # 8. OTHER
            # -------------------------------------------------------------------
            "home/*/.clouflared"
            "home/*/.steam"
            "home/*/.themes"
            "home/*/momentary"
          ];

          encryption_passcommand = "cat ${cfg.passphraseFile}"; # 🌟 Read from Option
          compression = "auto,zstd";
          ssh_command = "ssh -i ${cfg.sshKeyPath} -o StrictHostKeyChecking=no"; # 🌟 Read from Option
          keep_daily = 14;
          keep_weekly = 8;
          keep_monthly = 24;
          keep_yearly = 3;
          checks = [
            { name = "repository"; }
            { name = "archives"; }
          ];
          check_last = 3;
        };
      };
      systemd.timers.borgmatic = {
        timerConfig = {
          OnCalendar = "18:00";
          Persistent = true;
          RandomizedDelaySec = "5m";
        };
      };
      services.tailscale.enable = lib.mkForce true;
    };
}
