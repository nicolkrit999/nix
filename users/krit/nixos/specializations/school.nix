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

          (pkgs.writeShellScriptBin "tkgate-school" ''
            ${pkgs.xorg.xhost}/bin/xhost +local: >/dev/null 2>&1
            exec ${pkgs.distrobox}/bin/distrobox enter school-ubuntu -- tkgate "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "tkgate-school";
            desktopName = "tkGate (Ubuntu)";
            exec = "tkgate-school";
            icon = "tkgate";
          })

          # sqldeveloper-school wrapper: launches Oracle SQL Developer inside the school-arch
          # distrobox container with all env fixes needed for Java GUI on Wayland WMs.
          # All env var changes are scoped to this process only — no system-wide side effects.
          (pkgs.writeShellScriptBin "sqldeveloper-school" ''
            ${pkgs.xorg.xhost}/bin/xhost +local: >/dev/null 2>&1
            exec ${pkgs.distrobox}/bin/distrobox enter school-arch -- bash -c '
              # Derive JAVA_HOME from sqldeveloper own dependency (no hardcoded JDK version)
              JAVA_VER=$(pacman -Qi oracle-sqldeveloper 2>/dev/null | grep -oP "java-environment=\K\d+")
              if [ -z "$JAVA_VER" ]; then
                echo "oracle-sqldeveloper not ready yet. The setup service provisions it automatically on login."
                echo "Check progress: systemctl --user status school-distrobox-setup"
                exit 1
              fi
              export JAVA_HOME="/usr/lib/jvm/java-''${JAVA_VER}-openjdk"

              # _JAVA_AWT_WM_NONREPARENTING=1: Hyprland/Niri (Wayland WMs via XWayland) do not
              # reparent X11 windows. Java AWT expects reparenting and never paints the window
              # content without this flag — the window appears but is completely blank.
              export _JAVA_AWT_WM_NONREPARENTING=1

              # Disable XRender: XWayland XRender implementation has known issues that cause
              # blank or corrupted rendering in Java2D. Software fallback works reliably.
              export JAVA_TOOL_OPTIONS="-Dsun.java2d.xrender=false"

              # Force GDK to use X11 backend: distrobox leaks WAYLAND_DISPLAY from the host,
              # but the container only has an X11 socket via XWayland. JavaFX GtkApplication
              # crashes with "Internal Error" if GTK tries the Wayland backend.
              export GDK_BACKEND=x11

              sudo chmod +x /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper 2>/dev/null
              exec /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper "$@"
            ' _ "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "sqldeveloper-school";
            desktopName = "SQL Developer (School)";
            exec = "sqldeveloper-school";
            icon = "oracle-sqldeveloper";
          })

          # Manual trigger for the same self-healing logic as the systemd service.
          # Validates state, provisions anything missing, skips what's already good.
          (pkgs.writeShellScriptBin "school-distrobox-setup" ''
            set -euo pipefail
            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            mkdir -p "$EXPORT_PATH"

            container_exists() { distrobox list 2>/dev/null | grep -qw "$1"; }

            # --- Ubuntu container (tkgate) ---
            if ! container_exists "school-ubuntu"; then
              echo "==> Creating school-ubuntu..."
              distrobox create --name "school-ubuntu" --image "ubuntu:latest" --yes
            else
              echo "==> school-ubuntu exists."
            fi
            echo "==> Ensuring tkgate in school-ubuntu..."
            distrobox enter school-ubuntu -- bash -c '
              if command -v tkgate &>/dev/null; then
                echo "tkgate already installed"
              else
                sudo apt-get update && sudo apt-get install -y tkgate
              fi
            '

            # --- Arch container (AUR packages via makepkg) ---
            if ! container_exists "school-arch"; then
              echo "==> Creating school-arch..."
              distrobox create --name "school-arch" --image "archlinux:latest" --yes
            else
              echo "==> school-arch exists."
            fi
            echo "==> Ensuring runtime libs in school-arch..."
            distrobox enter school-arch -- sudo pacman -Syu --noconfirm --needed base-devel git libxrender libxtst libxi fontconfig ttf-dejavu gtk3 alsa-lib

            echo "==> Ensuring oracle-sqldeveloper in school-arch..."
            distrobox enter school-arch -- bash -c '
              if pacman -Qi oracle-sqldeveloper &>/dev/null; then
                echo "oracle-sqldeveloper already installed"
              else
                echo "Installing oracle-sqldeveloper from AUR via makepkg..."
                # Build on real disk — container /tmp is a 4GB tmpfs, too small for the 560MB+ sqldeveloper zip
                BUILDDIR="$HOME/.cache/aur-build"
                mkdir -p "$BUILDDIR"
                rm -rf "$BUILDDIR/oracle-sqldeveloper"
                git clone https://aur.archlinux.org/oracle-sqldeveloper.git "$BUILDDIR/oracle-sqldeveloper"
                cd "$BUILDDIR/oracle-sqldeveloper"
                TMPDIR="$BUILDDIR" makepkg -si --noconfirm
                rm -rf "$BUILDDIR/oracle-sqldeveloper"
              fi
            '
            distrobox enter school-arch -- sudo chmod +x /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper

            echo "==> Exporting binaries to $EXPORT_PATH..."
            distrobox enter school-arch -- distrobox-export --bin /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper --export-path "$EXPORT_PATH" 2>/dev/null || true

            echo ""
            echo "==> All school containers verified/provisioned."
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
        # 📦 DISTROBOX CONTAINER AUTO-SETUP (self-healing)
        # Validates actual container/package state on every login.
        # Fast skip when everything is present; full provision when
        # anything is missing (fresh boot, gc, specialization re-enable).
        # ------------------------------------------------------------
        systemd.user.services.school-distrobox-setup = {
          Unit = {
            Description = "Self-healing school distrobox provisioner";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            Type = "oneshot";
            RemainAfterExit = true;
            Restart = "on-failure";
            RestartSec = "30s";
            StartLimitIntervalSec = "600";
            StartLimitBurst = "5";
            ExecStart = "${pkgs.writeShellScript "school-distrobox-setup-exec" ''
              set -euo pipefail
              export PATH="${lib.makeBinPath [ pkgs.distrobox pkgs.podman pkgs.git pkgs.coreutils pkgs.bash ]}:$PATH"

              EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
              NEEDS_WORK=0

              # --- Validate current state ---
              container_exists() { distrobox list 2>/dev/null | grep -qw "$1"; }

              if ! container_exists "school-ubuntu"; then
                echo "school-ubuntu container missing."
                NEEDS_WORK=1
              elif ! distrobox enter school-ubuntu -- command -v tkgate &>/dev/null; then
                echo "tkgate not installed in school-ubuntu."
                NEEDS_WORK=1
              fi

              if ! container_exists "school-arch"; then
                echo "school-arch container missing."
                NEEDS_WORK=1
              elif ! distrobox enter school-arch -- pacman -Qi oracle-sqldeveloper &>/dev/null; then
                echo "oracle-sqldeveloper not installed in school-arch."
                NEEDS_WORK=1
              fi

              if [ "$NEEDS_WORK" -eq 0 ]; then
                echo "All school containers and packages verified. Nothing to do."
                exit 0
              fi

              echo "Provisioning missing school distrobox components..."
              mkdir -p "$EXPORT_PATH"

              # --- Ubuntu container (tkgate) ---
              if ! container_exists "school-ubuntu"; then
                echo "Creating school-ubuntu..."
                distrobox create --name "school-ubuntu" --image "ubuntu:latest" --yes
              fi
              distrobox enter school-ubuntu -- bash -c '
                if command -v tkgate &>/dev/null; then
                  echo "tkgate already installed"
                else
                  sudo apt-get update && sudo apt-get install -y tkgate
                fi
              '

              # --- Arch container (AUR packages via makepkg) ---
              if ! container_exists "school-arch"; then
                echo "Creating school-arch..."
                distrobox create --name "school-arch" --image "archlinux:latest" --yes
              fi
              # Runtime libs: X11 (Java AWT/Swing), GTK3 (JavaFX), fonts (X11FontManager), alsa (JavaFX media)
              distrobox enter school-arch -- sudo pacman -Syu --noconfirm --needed base-devel git libxrender libxtst libxi fontconfig ttf-dejavu gtk3 alsa-lib

              distrobox enter school-arch -- bash -c '
                if pacman -Qi oracle-sqldeveloper &>/dev/null; then
                  echo "oracle-sqldeveloper already installed"
                else
                  echo "Installing oracle-sqldeveloper from AUR via makepkg..."
                  # Build on real disk — container /tmp is a 4GB tmpfs, too small for the 560MB+ sqldeveloper zip
                  BUILDDIR="$HOME/.cache/aur-build"
                  mkdir -p "$BUILDDIR"
                  rm -rf "$BUILDDIR/oracle-sqldeveloper"
                  git clone https://aur.archlinux.org/oracle-sqldeveloper.git "$BUILDDIR/oracle-sqldeveloper"
                  cd "$BUILDDIR/oracle-sqldeveloper"
                  TMPDIR="$BUILDDIR" makepkg -si --noconfirm
                  rm -rf "$BUILDDIR/oracle-sqldeveloper"
                fi
              '
              distrobox enter school-arch -- sudo chmod +x /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper
              distrobox enter school-arch -- distrobox-export --bin /opt/oracle-sqldeveloper/sqldeveloper/bin/sqldeveloper --export-path "$EXPORT_PATH" 2>/dev/null || true

              echo "School distrobox provisioning complete."
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
