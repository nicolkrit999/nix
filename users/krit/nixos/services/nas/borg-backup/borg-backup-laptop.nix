{ delib
, lib
, config
, ...
}:
delib.module {
  name = "krit.services.nas.laptop-borg-backup";
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
          message = "krit.services.nas.laptop-borg-backup.passphraseFile is empty: the borg passphrase secret path is required.";
        }
        {
          assertion = cfg.sshKeyPath != "";
          message = "krit.services.nas.laptop-borg-backup.sshKeyPath is empty: the borg SSH key secret path is required.";
        }
      ];

      sops.secrets.borg-passphrase = { };
      sops.secrets.borg-private-key = { };
      myconfig.krit.services.nas.laptop-borg-backup = {
        passphraseFile = lib.mkDefault config.sops.secrets.borg-passphrase.path;
        sshKeyPath = lib.mkDefault config.sops.secrets.borg-private-key.path;
      };

      # Borg's cache and security dir (repo-location record) must outlive the tmpfs root,
      # otherwise every boot rebuilds the cache and re-trusts the repo.
      environment.persistence."/persist".directories = lib.mkIf myconfig.services.impermanence.enable [ "/var/lib/borgmatic" ];

      services.borgmatic = {
        enable = true;
        configurations."laptop-data" = {
          source_directories = [
            config.users.users.${myconfig.constants.user}.home
            "/persist"
          ];
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
            "/home/*/.config/discord/Cache" # Discord cache
            "/home/*/.config/discord/DawnGraphiteCache"
            "/home/*/.config/discord/discord_asset_cache"
            "/home/*/.config/discord/Service Worker"

            # Browsers (heavy, synced via their cloud accounts)
            "/home/*/.mozilla"
            "/home/*/.librewolf" # anchored: borg patterns are root-relative
            "/home/*/.librewolf-policyroot"
            "/home/*/.config/google-chrome"
            "/home/*/.config/chromium"
            "/home/*/.config/BraveSoftware"
            "/home/*/.config/zen" # declarative, relogin is fine
            "/home/*/.config/net.imput.helium"
            "/home/*/.config/google-chrome-headless"
            "/home/*/.config/Antigravity"
            "/home/*/.antigravity"

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
            "/home/*/.config/Code-School"
            "/home/*/.npm-global"
            "/home/*/.sqldeveloper"
            "/home/*/.eclipse"
            "/home/*/.headroom"
            "/home/*/.compose-cache"
            "/home/*/.java"
            "/home/*/.impeccable"
            "/home/*/.local/share/uv"
            "/home/*/.local/share/actual-mcp/node_modules"
            "/home/*/.local/share/media-downloader/bin"
            "/home/*/.local/share/school-env"
            "/home/*/.distrobox-bin"
            "/home/*/distrobox-bin"
            "/home/*/.local/share/nix-doom"
            "*/node_modules" # any depth (borg fnmatch: * crosses /)
            "*/.venv" # any depth
            "*/.direnv" # any depth

            # Specific app clutter
            "/home/*/.local/share/TelegramDesktop/tdata/emoji"
            "/home/*/.local/share/TelegramDesktop/tdata/temp"
            "/home/*/.local/share/Zeal" # Offline doc sets (re-downloadable)
            "/home/*/.local/share/nvim"
            "/home/*/.config/libreoffice/*/cache"
            "/home/*/.config/yazi/*"
            "/home/*/.config/sops/*"
            "/home/*/.local/share/containers" # Podman/Containers cache

            # Claude desktop
            "/home/*/.config/Claude/vm_bundles"
            "/home/*/.config/Claude/Cache"
            "/home/*/.config/Claude/Code Cache"
            "/home/*/.config/Claude/claude-code"
            "/home/*/.config/Claude/claude-code-vm"
            "/home/*/.config/Claude/Crashpad"
            "/home/*/.config/Claude/logs"

            # Claude Code (projects, memory, settings, history stay)
            "/home/*/.claude/plugins/cache"
            "/home/*/.claude/plugins/marketplaces"
            "/home/*/.claude/security/agent-sdk-venv"
            "/home/*/.claude/telemetry"
            "/home/*/.claude/paste-cache"
            "/home/*/.claude/shell-snapshots"
            "/home/*/.claude/image-cache"
            "/home/*/.claude/debug"
            "/home/*/.claude/statsig"
            "/home/*/.claude/todos"
            "/home/*/.local/share/claude/versions" # Claude Code binaries

            # Game launcher data (instances, accounts and cfg stay)
            "/home/*/.local/share/PrismLauncher/assets"
            "/home/*/.local/share/PrismLauncher/libraries"
            "/home/*/.local/share/PrismLauncher/meta"
            "/home/*/.local/share/PrismLauncher/cache"

            # Indexes and package stores
            "/home/*/.local/share/akonadi"
            "/home/*/.local/share/gvfs-metadata"
            "/home/*/.local/share/kactivitymanagerd"
            "/home/*/.local/share/flatpak" # Flatpak runtimes/apps (re-installable)
            "/home/*/.var/app/com.rtosta.zapzap" # removed ZapZap leftover

            # Clipboard history and Telegram client
            "/home/*/.local/share/vicinae/clipboard-data"
            "/home/*/.local/share/vicinae/clipboard.db*" # incl. -wal/-shm; shortcuts/snippets are kept
            "/home/*/.local/share/tgt" # only holds the login session
            "/home/*/.config/tgt"

            # Electron app web storage and caches
            "/home/*/.config/discord/Local Storage"
            "/home/*/.config/discord/IndexedDB"
            "/home/*/.config/discord/Crashpad"
            "/home/*/.config/discord/logs"
            "/home/*/.config/Equicord/Equicord/Cache"
            "/home/*/.config/Equicord/Equicord/Code Cache"
            "/home/*/.config/Equicord/Equicord/GPUCache"
            "/home/*/.config/Sidra/Cache"
            "/home/*/.config/Sidra/Local Storage"
            "/home/*/.config/Sidra/IndexedDB"
            "/home/*/.config/Vikunja Desktop/Cache"
            "/home/*/.config/Vikunja Desktop/IndexedDB"
            "/home/*/.config/Vikunja Desktop/Local Storage"

            # Folders backed up elsewhere or deliberately kept out of the repo
            "/home/*/github-repos" # Git repositories (includes the wallpapers repo)
            "/home/*/dotfiles" # Dotfiles repository
            "/home/*/dotfiles-private" # Private dotfiles repository
            "/home/*/.ssh" # Private keys stay out of the backup

            # Other
            "/home/*/.cloudflared" # was misspelled .clouflared, never matched
            "/home/*/.steam"
            "/home/*/.themes"
            "/home/*/momentary"

            # /persist: snapshots and re-creatable system state stay out of the backup
            "/persist/.snapshots"
            "/persist/var/lib/docker"
            "/persist/var/lib/containers"
            "/persist/var/lib/flatpak"
            "/persist/var/tmp"
            "/persist/var/cache/fscache"

            # Secure Boot signing keys: a root-only secret that never goes into the repo; the
            # encrypted offline copy is the backup (Documentation/usage/secure-boot/lanzaboote.md)
            myconfig.services.secure-boot.pkiBundle
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
        OnCalendar = [ "" "10:00" ];
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
      # The packaged service has ConditionACPower=true, which silently skipped the
      # 10:00 run on battery; the empty string resets the condition.
      systemd.services.borgmatic.unitConfig.ConditionACPower = "";
      myconfig.services.tailscale.enable = true;
    };
}
