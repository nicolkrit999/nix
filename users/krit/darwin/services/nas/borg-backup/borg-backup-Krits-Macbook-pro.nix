{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nas.Krits-MacBook-Pro-borg-backup";

  options.krit.services.nas.Krits-MacBook-Pro-borg-backup = with delib; {
    enable = boolOption false;
  };

  darwin.ifEnabled =
    { ... }:
    let
      nasUser = "krit";
      nasHost = "nicol-nas";
      hostName = config.networking.hostName;
      nasPath = "/volume1/Default-volume-1/0001_Docker/borgitory/${hostName}";
      passphraseFile = config.sops.secrets.borg-passphrase.path;
      sshKeyPath = config.sops.secrets.borg-private-key.path;

      excludes = [
        "/Users/krit/.config/borg-secrets"
        "/Users/krit/.ssh"
        "**/.DS_Store"
        "**/.stfolder*"
        "**/.stignore"
        "**/.localized"
        "*/Code Cache"
        "*/GPUCache"
        "*/DawnWebGPUCache"
        "*/DawnGraphiteCache"
        "*/Session Storage"
        "*/blob_storage"
        "*/PersistentCache"
        "*/.cache"
        "/Users/krit/Library/Caches"
        "*.log"
        "*.tmp"
        "*.bak"
        "*.sock"
        "*.vdi"
        "*.qcow2"
        "*.iso"
        "*.vmwarevm"
        "/Users/krit/Library"
        "/Users/krit/Applications"
        "/Users/krit/Downloads"
        "/Users/krit/Public"
        "/Users/krit/Music"
        "/Users/krit/Movies"
        "/Users/krit/Pictures/Photos Library.photoslibrary"
        "/Users/krit/Pictures/Photo Booth Library"
        "/Users/krit/Documents/Actual"
        "/Users/krit/school-workspace/github-repos"
        "/Users/krit/github-repos"
        "/Users/krit/dotfiles"
        "/Users/krit/tools"
        "/Users/krit/.config/portainer-mcp"
        "/Users/krit/.nix-defexpr"
        "/Users/krit/.nix-profile"
        "/Users/krit/.local"
        "/Users/krit/.npm"
        "/Users/krit/.m2"
        "/Users/krit/.gradle"
        "/Users/krit/.cargo"
        "/Users/krit/.vscode"
        "/Users/krit/.mozilla"
        "/Users/krit/.config/raycast"
        "/Users/krit/.config/kitty"
        "/Users/krit/.config/git"
        "/Users/krit/.config/nvim"
        "/Users/krit/.config/tmux"
        "/Users/krit/.config/alacritty"
        "/Users/krit/.config/bat"
        "/Users/krit/.config/stylix"
        "/Users/krit/.config/ranger"
        "/Users/krit/.config/fastfetch"
        "/Users/krit/.config/iterm2"
        "/Users/krit/.config/forge"
        "/Users/krit/.config/gdu"
        "/Users/krit/.config/gtk-3.0"
        "/Users/krit/.config/gtk-4.0"
        "/Users/krit/.config/blender"
        "/Users/krit/.config/starship.toml"
        "/Users/krit/.config/Code"
        "/Users/krit/.config/Cursor"
        "/Users/krit/.config/Vencord"
        "/Users/krit/.Trash"
        "/Users/krit/.terminfo"
        "/Users/krit/.themes"
        "/Users/krit/.lazygit"
        "/Users/krit/.zcompdump"
        "/Users/krit/.zsh_sessions"
        "/Users/krit/.zsh_history"
        "/Users/krit/.histfile"
        "/Users/krit/.zshrc"
        "/Users/krit/.zshrc_custom"
        "/Users/krit/.zshenv"
        "/Users/krit/.Xresources"
        "/Users/krit/.gtkrc-2.0"
        "/Users/krit/.CFUserTextEncoding"
        "/Users/krit/com.visualstudio.code.tunnel.plist"
      ];
    in
    {
      environment.systemPackages = with pkgs; [
        borgbackup
        borgmatic
      ];

      environment.etc."borgmatic/config.yaml".text = ''
        source_directories:
          - /Users/krit

        repositories:
          - path: ssh://${nasUser}@${nasHost}${nasPath}
            label: nas-repo

        exclude_patterns:
          ${builtins.concatStringsSep "\n    " (map (x: ''- "${x}"'') excludes)}

        compression: auto,zstd
        archive_name_format: '{hostname}-{now}'
        encryption_passcommand: cat ${passphraseFile}

        keep_daily: 7
        keep_weekly: 4
        keep_monthly: 6

        checks:
          - name: repository
          - name: archives

        ssh_command: ssh -i ${sshKeyPath} -o StrictHostKeyChecking=accept-new -o ConnectTimeout=30
      '';

      launchd.user.agents.borgmatic-backup = {
        serviceConfig = {
          Label = "com.borgmatic.backup";
          RunAtLoad = true;
          LowPriorityIO = true;
          Nice = 5;

          EnvironmentVariables = {
            BORG_PASSCOMMAND = "cat ${passphraseFile}";
            PATH = "${
              lib.makeBinPath [
                pkgs.borgmatic
                pkgs.openssh
                pkgs.coreutils
              ]
            }:/usr/bin:/bin:/usr/sbin:/sbin";
          };

          ProgramArguments = [
            "${pkgs.borgmatic}/bin/borgmatic"
            "--config"
            "/etc/borgmatic/config.yaml"
            "--syslog-verbosity"
            "1"
          ];

          StartCalendarInterval = [
            {
              Hour = 10;
              Minute = 0;
            }
            {
              Hour = 14;
              Minute = 0;
            }
            {
              Hour = 22;
              Minute = 0;
            }
          ];

          StandardOutPath = "/Users/krit/Library/Logs/borgmatic.log";
          StandardErrorPath = "/Users/krit/Library/Logs/borgmatic.err";
        };
      };

      services.tailscale.enable = lib.mkForce true;

      sops.secrets.borg-passphrase = {
        owner = "krit";
      };
      sops.secrets.borg-private-key = {
        owner = "krit";
      };
    };
}
