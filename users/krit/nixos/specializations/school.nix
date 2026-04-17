{ delib
, inputs
, config
, lib
, pkgs
, ...
}:
let
  myUserName = "krit";
  commonSecrets = ../../common/sops/krit-common-secrets-sops.yaml;
  c = config.myconfig.constants;
  term = c.terminal.name;
in
delib.module {
  name = "krit.specializations.school";
  options = delib.singleEnableOption false;

  # Import sops-nix to make sops.secrets available
  nixos.always = {
    imports = [ inputs.nix-sops.nixosModules.sops ];
  };

  nixos.ifEnabled = {
    nixpkgs.config.allowUnfree = true;
    # Isolated school-related sops secrets
    sops.secrets.school_ssh_key = {
      sopsFile = commonSecrets;
      owner = myUserName;
      path = "/home/${myUserName}/.ssh/id_school";
    };
    sops.secrets.school_ssh_pub = {
      sopsFile = commonSecrets;
      owner = myUserName;
      path = "/home/${myUserName}/.ssh/id_school.pub";
    };

    # 2. The actual specialization
    specialisation.school.configuration = {
      system.nixos.tags = [ "school" ];

      # Clear default profile behaviour
      myconfig.programs.hyprland.execOnce = lib.mkForce [
        "[workspace 1 silent] brave-school --app=https://www.icorsi.ch/"
        "[workspace 2 silent] vscode-school"
        "[workspace 3 silent] ${term} --class yazi -d $HOME/.school-workspace -e yazi"
        "[workspace 4 silent] ${term} -d $HOME/.school-workspace"
      ];
      myconfig.programs.hyprland.windowRules = lib.mkForce [ ];

      myconfig.programs.niri.execOnce = lib.mkForce [
        "brave-school --app=https://www.icorsi.ch/"
        "sleep 2 && vscode-school"
        "sleep 4 && ${term} --class yazi -d $HOME/.school-workspace -e yazi"
        "sleep 6 && ${term} -d $HOME/.school-workspace"
      ];

      # Override host-default constants for school specialization
      myconfig.constants.browser = lib.mkForce "brave-school";
      myconfig.constants.editor = lib.mkForce "vscode-school";

      # Self-contained virtualisation: school doesn't depend on the host's virtualisation.nix
      virtualisation.podman.enable = true;
      environment.systemPackages = with pkgs; [
        distrobox
        networkmanager-openconnect # For Cisco AnyConnect / GlobalProtect
        networkmanager-openvpn # For OpenVPN connections
        owncloud-client # OwnCloud desktop client
      ];


      # Configure allowed_signers for GPG SSH signing, and force git to use the school key and email
      home-manager.users.${myUserName} = { pkgs, lib, ... }: {
        nixpkgs.config.allowUnfree = true;

        home.activation.createSchoolDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.school-workspace/oneDrive || true
          mkdir -p $HOME/.school-workspace/owncloud || true
          mkdir -p $HOME/.school-workspace/github-repos || true
          mkdir -p $HOME/.school-workspace/momentary || true
          mkdir -p $HOME/.school-workspace/distrobox-bin || true
        '';

        # School distrobox exports go to isolated path (not ~/.distrobox-bin)
        home.sessionPath = [ "$HOME/.school-workspace/distrobox-bin" ];

        home.file.".ssh/allowed_signers".text = lib.mkForce ''
          kritpio.nicol@student.supsi.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66
        '';

        # Setup git identity and GPG signing with the school specialization key
        programs.git = {
          enable = true;
          settings = {
            user.email = lib.mkForce "kritpio.nicol@student.supsi.ch";
            user.name = lib.mkForce "Krit Pio Nicol-University";
            gpg.format = lib.mkForce "ssh";
            gpg.ssh.allowedSignersFile = "/home/${myUserName}/.ssh/allowed_signers";
            user.signingkey = lib.mkForce "/home/${myUserName}/.ssh/id_school";
            commit.gpgSign = lib.mkForce true;
          };
          signing = lib.mkForce {
            key = "/home/${myUserName}/.ssh/id_school";
            signByDefault = true;
          };
        };

        # 🎓 SSH Setup: Force student identity and block personal keys
        programs.ssh = {
          enable = true;
          enableDefaultConfig = lib.mkForce false;
          matchBlocks = {
            "github.com" = lib.mkForce {
              hostname = "github.com";
              identityFile = "/home/${myUserName}/.ssh/id_school";
              identitiesOnly = true;
              extraOptions = {
                "PubkeyAuthentication" = "yes";
              };
            };

            "gitlab.com" = lib.mkForce {
              hostname = "gitlab.com";
              identityFile = "/home/${myUserName}/.ssh/id_school";
              identitiesOnly = true;
            };
            "gitlab-edu.supsi.ch" = lib.mkForce {
              hostname = "gitlab-edu.supsi.ch";
              identityFile = "/home/${myUserName}/.ssh/id_school";
              identitiesOnly = true;
            };
          };
        };

        # 🐚 Workspace Alias
        programs.fish.shellAliases = { school = "cd ~/.school-workspace"; };
        programs.bash.shellAliases = { school = "cd ~/.school-workspace"; };
        programs.zsh.shellAliases = { school = "cd ~/.school-workspace"; };

        home.packages = with pkgs; [
          # Required Tools
          mars-mips # MIPS simulator (tecnica digitale)

          # CS Tools (usefule)
          dbeaver-bin
          insomnia
          wireshark
          zeal
          rclone

          # Custom Shell Scripts
          (pkgs.writeShellScriptBin "brave-school" ''exec ${pkgs.brave}/bin/brave --user-data-dir=$HOME/.config/BraveSoftware/School "$@"'')
          (pkgs.makeDesktopItem {
            name = "brave-school";
            desktopName = "Brave (School)";
            exec = "brave-school %U";
            icon = "brave";
          })

          (pkgs.writeShellScriptBin "vscode-school" ''exec ${pkgs.vscode}/bin/code --user-data-dir=$HOME/.config/Code-School --extensions-dir=$HOME/.vscode-school/extensions "$@"'')
          (pkgs.makeDesktopItem {
            name = "vscode-school";
            desktopName = "VSCode (School)";
            exec = "vscode-school %F";
            icon = "vscode";
          })

          (pkgs.writeShellScriptBin "idea-school" ''
            export XDG_CONFIG_HOME=$HOME/.config/school-env
            export XDG_DATA_HOME=$HOME/.local/share/school-env
            export XDG_CACHE_HOME=$HOME/.cache/school-env
            exec ${pkgs.jetbrains.idea}/bin/idea "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "idea-school";
            desktopName = "IDEA (School)";
            exec = "idea-school";
            icon = "idea";
          })

          (pkgs.writeShellScriptBin "tkgate-school" ''exec ${pkgs.distrobox}/bin/distrobox enter school-ubuntu -- tkgate "$@"'')
          (pkgs.makeDesktopItem {
            name = "tkgate-school";
            desktopName = "tkGate (Ubuntu)";
            exec = "tkgate-school";
            icon = "tkgate";
          })

          (pkgs.writeShellScriptBin "sqldeveloper-school" ''exec ${pkgs.distrobox}/bin/distrobox enter school-arch -- /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper "$@"'')
          (pkgs.makeDesktopItem {
            name = "sqldeveloper-school";
            desktopName = "SQL Developer (School)";
            exec = "sqldeveloper-school";
            icon = "oracle-sqldeveloper";
          })

          # Idempotent setup script for all school distrobox containers
          # Safe to re-run: checks for existing containers/packages before acting
          (pkgs.writeShellScriptBin "school-distrobox-setup" ''
            set -euo pipefail
            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            mkdir -p "$EXPORT_PATH"

            # --- Helper: create container if it doesn't exist ---
            ensure_container() {
              local name="$1" image="$2"
              if distrobox list | grep -q "$name"; then
                echo "==> Container '$name' already exists, skipping creation."
              else
                echo "==> Creating container '$name' from $image..."
                distrobox create --name "$name" --image "$image" --yes
              fi
            }

            # --- Ubuntu container (tkgate) ---
            ensure_container "school-ubuntu" "ubuntu:latest"
            echo "==> Ensuring tkgate is installed in school-ubuntu..."
            distrobox enter school-ubuntu -- bash -c '
              if command -v tkgate &>/dev/null; then
                echo "tkgate already installed"
              else
                sudo apt-get update && sudo apt-get install -y tkgate
              fi
            '

            # --- Arch container (AUR packages via makepkg) ---
            ensure_container "school-arch" "archlinux:latest"
            echo "==> Ensuring base-devel and git in school-arch..."
            distrobox enter school-arch -- sudo pacman -Syu --noconfirm --needed base-devel git

            echo "==> Ensuring oracle-sqldeveloper is installed in school-arch..."
            distrobox enter school-arch -- bash -c '
              if pacman -Qi oracle-sqldeveloper &>/dev/null; then
                echo "oracle-sqldeveloper already installed"
              else
                echo "Installing oracle-sqldeveloper from AUR via makepkg..."
                BUILDDIR=$(mktemp -d)
                git clone https://aur.archlinux.org/oracle-sqldeveloper.git "$BUILDDIR/oracle-sqldeveloper"
                cd "$BUILDDIR/oracle-sqldeveloper"
                makepkg -si --noconfirm
                rm -rf "$BUILDDIR"
              fi
            '

            # --- Export binaries to school-isolated path ---
            echo "==> Exporting binaries to $EXPORT_PATH..."
            distrobox enter school-arch -- distrobox-export --bin /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper --export-path "$EXPORT_PATH" 2>/dev/null || true

            echo ""
            echo "==> All school containers are ready!"
            echo "    Containers: school-ubuntu (tkgate), school-arch (AUR via makepkg)"
            echo "    Exported binaries: $EXPORT_PATH"
            echo ""
            echo "    To add more AUR packages, run school-distrobox-setup or manually:"
            echo "      distrobox enter school-arch"
            echo "      # Then inside: git clone https://aur.archlinux.org/PKG.git && cd PKG && makepkg -si --noconfirm"
            echo "      distrobox enter school-arch -- distrobox-export --bin /usr/bin/BINARY --export-path $EXPORT_PATH"
          '')
        ];

        # ------------------------------------------------------------
        # ☁️ RCLONE ONEDRIVE SYSTEMD SERVICE
        # ------------------------------------------------------------
        systemd.user.services.school-onedrive-mount = {
          Unit = {
            Description = "Mount School OneDrive via Rclone";
            After = [ "network-online.target" ];
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            # Mount the remote named "school-onedrive" to the local folder with VFS caching
            ExecStart = "${pkgs.rclone}/bin/rclone mount school-onedrive: %h/.school-workspace/oneDrive --vfs-cache-mode full --vfs-cache-max-size 10G --dir-cache-time 48h";
            ExecStop = "/run/wrappers/bin/fusermount -u %h/.school-workspace/oneDrive";
            Type = "notify";
            Restart = "on-failure";
            RestartSec = "10s";
            Environment = [ "PATH=/run/wrappers/bin/:$PATH" ];
          };
        };

        # ------------------------------------------------------------
        # 📦 DISTROBOX CONTAINER AUTO-SETUP
        # ------------------------------------------------------------
        systemd.user.services.school-distrobox-setup = {
          Unit = {
            Description = "Setup school distrobox containers (idempotent, stamp-guarded)";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            # Retry on failure (network/podman not ready yet)
            Restart = "on-failure";
            RestartSec = "30s";
            # Give up after 5 attempts within 10 minutes
            StartLimitIntervalSec = "600";
            StartLimitBurst = "5";
            ExecStart = "${pkgs.writeShellScript "school-distrobox-setup-exec" ''
              set -euo pipefail
              export PATH="${lib.makeBinPath [ pkgs.distrobox pkgs.podman pkgs.git pkgs.coreutils pkgs.bash ]}:$PATH"

              STAMP="$HOME/.school-workspace/.distrobox-setup-done"
              EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"

              # Skip if already completed (delete stamp to force re-run)
              if [ -f "$STAMP" ]; then
                echo "Stamp file exists, skipping setup. Remove $STAMP to force re-run."
                exit 0
              fi

              mkdir -p "$EXPORT_PATH"

              ensure_container() {
                local name="$1" image="$2"
                if distrobox list | grep -q "$name"; then
                  echo "Container '$name' already exists."
                else
                  echo "Creating container '$name' from $image..."
                  distrobox create --name "$name" --image "$image" --yes
                fi
              }

              # --- Ubuntu container (tkgate) ---
              ensure_container "school-ubuntu" "ubuntu:latest"
              distrobox enter school-ubuntu -- bash -c '
                if command -v tkgate &>/dev/null; then
                  echo "tkgate already installed"
                else
                  sudo apt-get update && sudo apt-get install -y tkgate
                fi
              '

              # --- Arch container (AUR packages via makepkg) ---
              ensure_container "school-arch" "archlinux:latest"
              distrobox enter school-arch -- sudo pacman -Syu --noconfirm --needed base-devel git

              distrobox enter school-arch -- bash -c '
                if pacman -Qi oracle-sqldeveloper &>/dev/null; then
                  echo "oracle-sqldeveloper already installed"
                else
                  echo "Installing oracle-sqldeveloper from AUR via makepkg..."
                  BUILDDIR=$(mktemp -d)
                  git clone https://aur.archlinux.org/oracle-sqldeveloper.git "$BUILDDIR/oracle-sqldeveloper"
                  cd "$BUILDDIR/oracle-sqldeveloper"
                  makepkg -si --noconfirm
                  rm -rf "$BUILDDIR"
                fi
              '

              distrobox enter school-arch -- distrobox-export --bin /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper --export-path "$EXPORT_PATH" 2>/dev/null || true

              # Mark setup as complete
              touch "$STAMP"
              echo "School distrobox setup complete."
            ''}";
          };
        };

        # ------------------------------------------------------------
        # PROGRESSIVE WEB APPS & ISOLATED APPS
        # ------------------------------------------------------------
        xdg.desktopEntries =
          let
            makeSchoolPwa = name: url: icon: startupClass: {
              name = "school-pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
              value = {
                name = name;
                genericName = "School Web App";
                comment = "Launch ${name}";
                exec = "brave-school --app=\"${url}\" --password-store=basic";
                icon = icon;
                settings = { StartupWMClass = startupClass; };
                terminal = false;
                type = "Application";
                categories = [ "Education" ];
                mimeType = [ "x-scheme-handler/https" "x-scheme-handler/http" ];
              };
            };
          in
          builtins.listToAttrs [
            (makeSchoolPwa "SUPSI Portal" "https://portalestudenti.supsi.ch/" "education" "brave-portalestudenti.supsi.ch__-Default")
            (makeSchoolPwa "iCorsi" "https://www.icorsi.ch/" "applications-education" "brave-www.icorsi.ch__-Default")
            (makeSchoolPwa "School OwnCloud" "https://owncloud.nicolkrit.ch/" "folder-cloud" "brave-owncloud.nicolkrit.ch__-Default")
            (makeSchoolPwa "NotebookLM" "https://notebooklm.google.com/" "utilities-terminal" "brave-notebooklm.google.com__-Default")
            (makeSchoolPwa "USI Rooms" "https://usirooms.xyz/" "office-calendar" "brave-usirooms.xyz__-Default")
            (makeSchoolPwa "School OneDrive" "https://supsi-my.sharepoint.com/personal/kritpio_nicol_supsi_ch/_layouts/15/onedrive.aspx?sw=bypass&bypassReason=abandoned&startedResponseCatch=true" "folder-remote" "brave-supsi--my.sharepoint.com__-Default")
            (makeSchoolPwa "Lecture Calendar" "https://calendar.google.com/calendar/u/0?cid=NDg0Zjg5MjUyOThlY2M0YzA2NWVkMTNhNGIwM2I4MjdlNTY0YWM5OWRlYjBjMDE0NThiNTZiOWY3MGY3ZmI5Y0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t" "x-office-calendar" "brave-calendar.google.com__-Default")
          ];
      };
    };
  };
}
