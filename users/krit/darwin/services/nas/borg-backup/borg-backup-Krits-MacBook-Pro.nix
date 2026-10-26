{ delib
, config
, lib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.nas.Krits-MacBook-Pro-borg-backup";
  options = delib.singleEnableOption false;

  darwin.ifEnabled =
    { myconfig, ... }:
    let
      nas = myconfig.krit.services.nas;
      user = myconfig.constants.user;
      home = config.users.users.${user}.home;
      nasUser = nas.user;
      hostName = config.networking.hostName;
      nasPath = "/volume1/Default-volume-1/0001_Docker/borgitory/${hostName}";
      passphraseFile = config.sops.secrets.borg-passphrase.path;
      sshKeyPath = config.sops.secrets.borg-private-key.path;

      excludes = [
        # Secrets and private keys stay out of the NAS repo
        "${home}/.ssh"
        "${home}/.config/sops"
        "${home}/dotfiles-private"

        # Cache and junk patterns
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
        "${home}/Library/Caches"
        "*.log"
        "*.tmp"
        "*.bak"
        "*.sock"
        "*.vdi"
        "*.qcow2"
        "*.iso"
        "*.vmwarevm"

        # Heavy or re-creatable standard directories
        "${home}/Library"
        "${home}/Applications"
        "${home}/Downloads"
        "${home}/Public"
        "${home}/Music"
        "${home}/Movies"
        "${home}/Pictures/Photos Library.photoslibrary"
        "${home}/Pictures/Photo Booth Library"
        "${home}/Documents/Actual"
        "${home}/.Trash"

        # Backed up elsewhere or deliberately kept out of the repo
        "${home}/school-workspace/github-repos"
        "${home}/github-repos"
        "${home}/dotfiles"
        "${home}/momentary"
        "${home}/tools"

        # Developer tools and package caches
        "${home}/.nix-defexpr"
        "${home}/.nix-profile"
        "${home}/.local"
        "${home}/.npm"
        "${home}/.m2"
        "${home}/.gradle"
        "${home}/.cargo"
        "${home}/.vscode"
        "${home}/.mozilla"

        # Regenerated app config (managed by nix or the app itself)
        "${home}/.config/portainer-mcp"
        "${home}/.config/raycast"
        "${home}/.config/kitty"
        "${home}/.config/git"
        "${home}/.config/nvim"
        "${home}/.config/tmux"
        "${home}/.config/alacritty"
        "${home}/.config/bat"
        "${home}/.config/stylix"
        "${home}/.config/ranger"
        "${home}/.config/iterm2"
        "${home}/.config/forge"
        "${home}/.config/gdu"
        "${home}/.config/gtk-3.0"
        "${home}/.config/gtk-4.0"
        "${home}/.config/blender"
        "${home}/.config/starship.toml"
        "${home}/.config/Code"
        "${home}/.config/Cursor"
        "${home}/.config/Vencord"
        "${home}/.config/Equicord"

        # Shell and misc dotfiles
        "${home}/.terminfo"
        "${home}/.themes"
        "${home}/.lazygit"
        "${home}/.zcompdump"
        "${home}/.zsh_sessions"
        "${home}/.zsh_history"
        "${home}/.histfile"
        "${home}/.zshrc"
        "${home}/.zshrc_custom"
        "${home}/.zshenv"
        "${home}/.Xresources"
        "${home}/.gtkrc-2.0"
        "${home}/.CFUserTextEncoding"
        "${home}/com.visualstudio.code.tunnel.plist"
      ];
    in
    {
      environment.systemPackages = [
        pkgs.borgbackup
        pkgs.borgmatic
      ];

      # UNTESTED ON A REAL MAC (no Mac exists, CI only). Verify when one is available:
      #  - The repository URL uses the pinned FQDN (was the short ssh alias). Borg treats a
      #    changed URL as a relocated repo: a non-interactive run may abort with a "previously
      #    located at" message when ~/.config/borg/security already holds the old location.
      #    Run once by hand with BORG_RELOCATED_REPO_ACCESS_IS_OK=yes borgmatic to record it
      #    (the chunk cache is rebuilt once).
      #  - The pin lives in /etc/ssh/ssh_known_hosts (programs.ssh.knownHosts); check that the
      #    nix openssh first in the agent PATH reads it, otherwise the strict check fails.
      #  - borgmatic exports encryption_passcommand itself, so the agent sets no
      #    BORG_PASSCOMMAND; confirm the first scheduled run unlocks the repo.
      #  - The agent has no RunAtLoad: launchd runs a missed StartCalendarInterval slot once
      #    after wake, and a rebuild no longer triggers a full backup. Confirm that on a Mac.
      environment.etc."borgmatic/config.yaml".text = builtins.toJSON {
        source_directories = [ home ];
        repositories = [
          {
            path = "ssh://${nasUser}@${nas.host}${nasPath}";
            label = "nas-repo";
          }
        ];
        exclude_patterns = excludes;
        compression = "auto,zstd";
        archive_name_format = "{hostname}-{now}";
        encryption_passcommand = "cat ${passphraseFile}";
        keep_daily = 7;
        keep_weekly = 4;
        keep_monthly = 6;
        checks = [
          { name = "repository"; frequency = "2 weeks"; }
          { name = "archives"; frequency = "2 weeks"; }
        ];
        check_last = 3;
        # Host key checking is strict: the NAS key is pinned in /etc/ssh/ssh_known_hosts
        # (nas-identity.nix).
        ssh_command = "ssh -i ${sshKeyPath} -o IdentitiesOnly=yes -o ConnectTimeout=30";
      };

      launchd.user.agents.borgmatic-backup = {
        serviceConfig = {
          Label = "com.borgmatic.backup";
          LowPriorityIO = true;
          Nice = 5;

          EnvironmentVariables = {
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

          StandardOutPath = "${home}/Library/Logs/borgmatic.log";
          StandardErrorPath = "${home}/Library/Logs/borgmatic.err";
        };
      };

      # Tailnet access on darwin comes from the tailscale-app cask (hosts/Krits-MacBook-Pro/local-packages.nix).
      assertions = [
        {
          assertion = myconfig.services.tailscale.darwinCaskPresent || config.services.tailscale.enable;
          message = "krit.services.nas.Krits-MacBook-Pro-borg-backup reaches the NAS over the tailnet but this darwin host has no Tailscale provider: add the Homebrew cask \"tailscale-app\" or enable myconfig.services.tailscale.";
        }
      ];

      sops.secrets.borg-passphrase.owner = user;
      sops.secrets.borg-private-key.owner = user;
    };
}
