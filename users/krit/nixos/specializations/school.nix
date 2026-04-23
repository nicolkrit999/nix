{ delib
, inputs
, config
, lib
, pkgs
, ...
}:
let
  myUserName = config.myconfig.constants.user;
  commonSecrets = ../../common/sops/krit-common-secrets-sops.yaml;
  c = config.myconfig.constants;
  term = c.terminal.name;

  # Distrobox apps to provision — each entry defines a container and how to check/install.
  # The check script and setup script both derive from this list.
  distroboxApps = [
    {
      name = "tkgate";
      container = "school-ubuntu";
      image = "ubuntu:latest";
      check = "command -v tkgate";
      install = "sudo apt-get update && sudo apt-get install -y tkgate";
    }
    {
      name = "oracle-sqldeveloper";
      container = "school-arch";
      image = "archlinux:latest";
      check = "test -x /opt/sqldeveloper/sqldeveloper.sh";
      preInstall = "sudo pacman -Syu --noconfirm --needed jdk17-openjdk fzf libxrender libxtst libxi fontconfig ttf-dejavu gtk3 alsa-lib";
      install = builtins.concatStringsSep "\n" [
        ''RPM=$(ls $HOME/nix/users/krit/src/vendor-bins/oracle-sqldeveloper/sqldeveloper-*.noarch.rpm 2>/dev/null | head -1)''
        ''if [ -z "$RPM" ]; then''
        ''  echo "ERROR: Download sqldeveloper-*.noarch.rpm from:"''
        ''  echo "  https://www.oracle.com/database/sqldeveloper/technologies/download/"''
        ''  echo "Place it in: ~/nix/users/krit/src/vendor-bins/oracle-sqldeveloper/"''
        ''  exit 1''
        ''fi''
        ''sudo bsdtar -xf "$RPM" -C /''
      ];
      postInstall = builtins.concatStringsSep "\n" [
        "sudo chmod +x /opt/sqldeveloper/sqldeveloper.sh"
        # Pre-configure JDK path so sqldeveloper.sh doesn't prompt interactively on first run
        "sudo sed -i 's|^#\\?SetJavaHome.*|SetJavaHome /usr/lib/jvm/java-17-openjdk|' /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf 2>/dev/null || true"
        "grep -q 'SetJavaHome' /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf 2>/dev/null || echo 'SetJavaHome /usr/lib/jvm/java-17-openjdk' | sudo tee -a /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf >/dev/null"
      ];
    }
  ];

  # Fast startup check: only verifies container existence via podman (instant, no container start).
  # User files live in $HOME (bind-mounted into containers), safe from any cleanup.
  # Containers live in /var/lib/containers (persisted via impermanence), NOT in /nix/store —
  # nix-collect-garbage does not touch them. They only disappear via manual podman/distrobox rm.
  distroboxStartupCheck = pkgs.writeShellScript "school-distrobox-startup-check" ''
    MISSING=""
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
        MISSING="$MISSING ${app.name}"
      fi
    '') distroboxApps}

    if [ -n "$MISSING" ]; then
      echo "Missing distrobox containers:$MISSING"
      echo "Run: school-distrobox-setup"
    else
      echo "Distrobox containers found. Run school-distrobox-check to verify tools are installed."
    fi
  '';

  # Deep check: enters each container and verifies the actual package is installed.
  distroboxDeepCheck = pkgs.writeShellScript "school-distrobox-deep-check" ''
    # Check that the SQL Developer RPM exists before anything else
    RPM=$(ls $HOME/nix/users/krit/src/vendor-bins/oracle-sqldeveloper/sqldeveloper-*.noarch.rpm 2>/dev/null | head -1)
    if [ -z "$RPM" ]; then
      echo "Missing: sqldeveloper RPM file"
      echo "  Download from: https://www.oracle.com/database/sqldeveloper/technologies/download/"
      echo "  Place the .rpm in: ~/nix/users/krit/src/vendor-bins/oracle-sqldeveloper/"
      exit 1
    fi

    MISSING=""
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
        MISSING="$MISSING ${app.name}(no container)"
      elif ! ${pkgs.distrobox}/bin/distrobox enter ${app.container} -- bash -c '${app.check}' &>/dev/null; then
        MISSING="$MISSING ${app.name}(not installed)"
      fi
    '') distroboxApps}

    if [ -n "$MISSING" ]; then
      echo "Missing distrobox tools:$MISSING"
      echo "Run: school-distrobox-setup"
      exit 1
    else
      echo "All distrobox tools are present and verified."
    fi
  '';

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

      myconfig.programs.mango.execOnce = lib.mkForce [
        "sh -c 'sleep 1 && brave-school --app=https://www.icorsi.ch/'"
        "sh -c 'sleep 2 && vscode-school'"
        "sh -c 'sleep 4 && ${term} --class yazi -d $HOME/.school-workspace -e yazi'"
        "sh -c 'sleep 6 && ${term} -d $HOME/.school-workspace'"
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

        # 🐚 Workspace Alias (shell-agnostic via home.shellAliases)
        home.shellAliases = { school = "cd ~/.school-workspace"; };

        # On interactive shell start, check if distrobox tools are present
        programs.fish.interactiveShellInit = lib.mkIf (c.shell == "fish") ''
          ${distroboxStartupCheck} 2>/dev/null
        '';
        programs.bash.initExtra = lib.mkIf (c.shell == "bash") ''
          ${distroboxStartupCheck} 2>/dev/null
        '';
        programs.zsh.initContent = lib.mkIf (c.shell == "zsh") ''
          ${distroboxStartupCheck} 2>/dev/null
        '';

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
              if [ ! -x /opt/sqldeveloper/sqldeveloper.sh ]; then
                echo "oracle-sqldeveloper is not installed. Run: school-distrobox-setup"
                exit 1
              fi
              export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
              export _JAVA_AWT_WM_NONREPARENTING=1
              export JAVA_TOOL_OPTIONS="-Dsun.java2d.xrender=false"
              export GDK_BACKEND=x11
              exec /opt/sqldeveloper/sqldeveloper.sh "$@"
            ' _ "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "sqldeveloper-school";
            desktopName = "SQL Developer (School)";
            exec = "sqldeveloper-school";
            icon = "oracle-sqldeveloper";
          })

          # Idempotent setup: creates containers and installs only what's missing.
          (pkgs.writeShellScriptBin "school-distrobox-setup" ''
            set -uo pipefail
            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            mkdir -p "$EXPORT_PATH"
            FAILURES=0

            container_exists() { ${pkgs.podman}/bin/podman container exists "$1" 2>/dev/null; }

            ${lib.concatMapStringsSep "\n\n" (app: ''
              # --- ${app.name} in ${app.container} ---
              echo "==> Checking ${app.name}..."
              if ! container_exists "${app.container}"; then
                echo "    Creating ${app.container}..."
                if ! distrobox create --name "${app.container}" --image "${app.image}" --yes; then
                  echo "    FAILED to create ${app.container}"
                  FAILURES=$((FAILURES + 1))
                fi
              fi
              if container_exists "${app.container}"; then
                ${lib.optionalString (app ? preInstall) ''
                echo "    Installing dependencies in ${app.container}..."
                distrobox enter ${app.container} -- bash -c '${app.preInstall}' || true
                ''}
                if distrobox enter ${app.container} -- bash -c '${app.check}' &>/dev/null; then
                  echo "    ${app.name} already installed, skipping."
                else
                  echo "    Installing ${app.name}..."
                  if ! distrobox enter ${app.container} -- bash -c '${app.install}'; then
                    echo "    FAILED to install ${app.name}"
                    FAILURES=$((FAILURES + 1))
                  else
                    ${lib.optionalString (app ? postInstall) ''
                    distrobox enter ${app.container} -- bash -c '${app.postInstall}' || true
                    ''}
                    echo "    ${app.name} installed."
                  fi
                fi
              fi
            '') distroboxApps}

            if [ "$FAILURES" -gt 0 ]; then
              echo ""
              echo "==> $FAILURES tool(s) failed to provision."
              exit 1
            fi
            echo ""
            echo "==> All school distrobox tools are ready."
          '')

          # Deep check: verifies packages are actually installed inside containers
          (pkgs.writeShellScriptBin "school-distrobox-check" ''
            exec ${distroboxDeepCheck}
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
