{ delib
, lib
, config
, ...
}:
delib.module {
  name = "krit.services.nas.desktop-borg-backup";
  options = with delib; moduleOptions {
    enable = boolOption false;
    passphraseFile = strOption "";
    sshKeyPath = strOption "";
  };

  nixos.ifEnabled =
    { cfg, myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      nasUser = "krit";
      nasPath = "/volume1/Default-volume-1/0001_Docker/borgitory/${config.networking.hostName}";
    in
    {
      assertions = [
        {
          assertion = cfg.passphraseFile != "";
          message = "krit.services.nas.desktop-borg-backup.passphraseFile is empty: the borg passphrase secret path is required.";
        }
        {
          assertion = cfg.sshKeyPath != "";
          message = "krit.services.nas.desktop-borg-backup.sshKeyPath is empty: the borg SSH key secret path is required.";
        }
      ];

      sops.secrets.borg-passphrase = { };
      sops.secrets.borg-private-key = { };
      myconfig.krit.services.nas.desktop-borg-backup = {
        passphraseFile = lib.mkDefault config.sops.secrets.borg-passphrase.path;
        sshKeyPath = lib.mkDefault config.sops.secrets.borg-private-key.path;
      };

      # Borg's cache and security dir (repo-location record) must outlive the tmpfs root,
      # otherwise every boot rebuilds the cache and re-trusts the repo.
      environment.persistence."/persist".directories = lib.mkIf myconfig.services.impermanence.enable [ "/var/lib/borgmatic" ];

      services.borgmatic = {
        enable = true;
        configurations."desktop-data" = {
          source_directories = [ config.users.users.${myconfig.constants.user}.home ];
          repositories = [
            {
              path = "ssh://${nasUser}@${nas.host}${nasPath}";
              label = "nas-repo";
            }
          ];
          exclude_patterns = [
            # Generic Electron cache junk (Discord, Obsidian, VSCode, Slack, Element, ...)
            "*/Code Cache" # VSCode & Electron apps
            "*/GPUCache" # Electron apps
            "*/DawnWebGPUCache" # Electron apps
            "*/Session Storage" # Electron apps
            "*/blob_storage" # Electron apps
            "*/PersistentCache" # Common in Spotify/Media apps

            # Noisy file extensions
            "*.log" # Log files
            "*.tmp" # Temporary files
            "*.bak" # Backup files
            "*.sock" # Socket files
            "*.vdi" # VirtualBox Disks
            "*.qcow2" # QEMU Disks
            "*.iso" # Disk Images

            # Heavy standard directories
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

            # Browsers (heavy, synced via their cloud accounts)
            "/home/*/.mozilla"
            "/home/*/.librewolf" # anchored: borg patterns are root-relative
            "/home/*/.librewolf-policyroot"
            "/home/*/.config/google-chrome"
            "/home/*/.config/chromium"
            "/home/*/.config/BraveSoftware"

            # Developer tools and languages
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

            # Specific app clutter
            "/home/*/.local/share/TelegramDesktop/tdata/emoji"
            "/home/*/.local/share/TelegramDesktop/tdata/temp"
            "/home/*/.local/share/Zeal" # Offline doc sets (re-downloadable)
            "/home/*/.local/share/nvim"
            "/home/*/.config/libreoffice/*/cache"
            "/home/*/.config/yazi/*"
            "/home/*/.config/sops/*"
            "/home/*/.local/share/containers" # Podman/Containers cache

            # Folders backed up elsewhere or deliberately kept out of the repo
            "/home/*/github-repos" # Git repositories (includes the wallpapers repo)
            "/home/*/dotfiles" # Dotfiles repository
            "/home/*/dotfiles-private" # Private dotfiles repository
            "/home/*/.ssh" # Private keys stay out of the backup
            "/home/*/.school-workspace" # Already backed up by other methods

            # Other
            "/home/*/.cloudflared" # was misspelled .clouflared, never matched
            "/home/*/.steam"
            "/home/*/.themes"
            "/home/*/momentary"
          ];

          encryption_passcommand = "cat ${cfg.passphraseFile}";
          compression = "auto,zstd";
          ssh_command = "ssh -i ${cfg.sshKeyPath} -o IdentitiesOnly=yes";
          # Changing the repository URL makes borg treat the repo as relocated: a fresh
          # security dir records the new location, an existing one aborts the run.
          borg_base_directory = "/var/lib/borgmatic";
          keep_daily = 14;
          keep_weekly = 8;
          keep_monthly = 24;
          keep_yearly = 3;
          checks = [
            { name = "repository"; frequency = "2 weeks"; }
            { name = "archives"; frequency = "2 weeks"; }
          ];
          check_last = 3;
        };
      };
      # The packaged borgmatic.timer ships OnCalendar=daily; list entries add to it
      # and the empty string resets it, so only the time below remains.
      systemd.timers.borgmatic.timerConfig = {
        OnCalendar = [ "" "18:00" ];
        Persistent = true;
        RandomizedDelaySec = "5m";
      };
      myconfig.services.tailscale.enable = true;
    };
}
