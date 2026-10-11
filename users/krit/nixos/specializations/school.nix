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

  # HiDPI scale for the distrobox-launched X11/Java tools below (tkgate,
  # SQL Developer). Matches each host's physical panel, mirroring the
  # Hyprland monitor "scale" already declared for it (see
  # hosts/nixos-desktop/default.nix, hosts/nixos-laptop/default.nix).
  # Deliberately static, not queried from the running compositor: scale is
  # a property of the panel, not of whichever WM/DE happens to be active.
  guiScale =
    if c.hostname == "nixos-desktop" then
      1.5
    else if c.hostname == "nixos-laptop" then
      1.6
    else
      1.0;
  guiScaleStr = toString guiScale;
  xftDpi = toString (builtins.floor (96 * guiScale));

  # Self-contained OpenCloud mount for the school workspace: mounted directly
  # into $HOME/.school-workspace/opencloud regardless of whether
  # krit.services.nas.opencloud-mount is enabled on the host. Reuses that
  # module's space list and the always-present "davfs-secrets" sops template
  # (see templates/krit/sops/service-wiring.nix) so the school profile never
  # depends on the default profile's NAS mount being turned on.
  schoolOpencloudSpaces = config.myconfig.krit.services.nas.opencloud-mount.spaces;
  schoolOpencloudMountPoint = "/home/${myUserName}/.school-workspace/opencloud";
  # I-16: davfs2 resolves names, so follow the constant instead of a numeric uid.
  schoolOpencloudUid = myUserName;
  schoolOpencloudGid = config.users.users.${myUserName}.group;
  mkSchoolOpencloudFileSystem = space: {
    name = "${schoolOpencloudMountPoint}/${space.path}";
    value = {
      device = space.url;
      fsType = "davfs";
      options = [
        "uid=${schoolOpencloudUid}"
        "gid=${schoolOpencloudGid}"
        "file_mode=0664"
        "dir_mode=0775"
        "_netdev"
        "nofail"
        "noauto"
        "x-systemd.automount"
      ];
    };
  };

  distroboxApps = [
    {
      name = "tkgate";
      container = "school-ubuntu";
      image = "ubuntu:latest";
      check = "command -v tkgate";
      rootInit = builtins.concatStringsSep " && " [
        "[ -f /etc/sudoers ] || cp /etc/sudoers.dpkg-new /etc/sudoers"
        "chmod 440 /etc/sudoers"
        "DEBIAN_FRONTEND=noninteractive dpkg --configure -a"
      ];
      install = "sudo apt-get update && sudo apt-get install -y tkgate";
    }
    {
      name = "oracle-sqldeveloper";
      container = "school-arch";
      image = "archlinux:latest";
      check = "test -x /opt/sqldeveloper/sqldeveloper.sh";
      preInstall = "sudo pacman -Syu --noconfirm --needed jdk17-openjdk fzf libxrender libxtst libxi fontconfig ttf-dejavu gtk3 alsa-lib";
      install = builtins.concatStringsSep "\n" [
        "RPM=$(ls $HOME/dotfiles-private/various/binaries/oracle-sql-developer/sqldeveloper-*.noarch.rpm 2>/dev/null | head -1)"
        ''if [ -z "$RPM" ]; then''
        ''echo "ERROR: Download sqldeveloper-*.noarch.rpm from:"''
        ''echo "  https://www.oracle.com/database/sqldeveloper/technologies/download/"''
        ''echo "Place it in: ~/dotfiles-private/various/binaries/oracle-sql-developer/"''
        "exit 1"
        "fi"
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
    RPM=$(ls $HOME/dotfiles-private/various/binaries/oracle-sql-developer/sqldeveloper-*.noarch.rpm 2>/dev/null | head -1)
    if [ -z "$RPM" ]; then
      echo "Missing: sqldeveloper RPM file"
      echo "  Download from: https://www.oracle.com/database/sqldeveloper/technologies/download/"
      echo "  Place the .rpm in: ~/dotfiles-private/various/binaries/oracle-sql-developer/"
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
      myconfig.programs.hyprland.execOnce = lib.mkForce (
        if c.hostname == "nixos-desktop" then
          [
            "[workspace 2 silent] ${term} --class nvim-school -d $HOME/.school-workspace -e nvim"
            "[workspace 3 silent] ${term} --class yazi -d $HOME/.school-workspace -e yazi"
            "[workspace 7 silent] brave-school --app=https://www.icorsi.ch/"
            "[workspace 8 silent] ${term} -d $HOME/.school-workspace"
          ]
        else if c.hostname == "nixos-laptop" then
          [
            "[workspace 2 silent] ${term} --class nvim-school -d $HOME/.school-workspace -e nvim"
            "[workspace 3 silent] ${term} --class yazi -d $HOME/.school-workspace -e yazi"
            "[workspace 4 silent] ${term} -d $HOME/.school-workspace"
            "[workspace 5 silent] brave-school --app=https://www.icorsi.ch/"
          ]
        else
          [ ]
      );
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
      myconfig.constants.editor = lib.mkForce "nvim";
      myconfig.constants.shell = lib.mkForce "bash";

      # Force exit-node off on every boot into this specialisation, regardless
      # of whatever exit-node state tailscale persisted from the last boot.
      # Type=exec so it never blocks boot; tailscale set works on prefs while
      # logged out, so retrying the set itself also covers booting offline (I-03).
      systemd.services.tailscale-school-exit-node-off = lib.mkIf config.services.tailscale.enable {
        description = "Force tailscale exit-node off for the school specialisation";
        after = [
          "tailscaled.service"
          "tailscale-autoconnect.service"
        ];
        wants = [
          "tailscaled.service"
          "tailscale-autoconnect.service"
        ];
        wantedBy = [ "multi-user.target" ];

        path = [ pkgs.tailscale ];

        serviceConfig.Type = "exec";

        script = ''
          for i in $(seq 1 60); do
            timeout 5 tailscale set --exit-node= && exit 0
            sleep 3
          done
          echo "tailscale-school-exit-node-off: could not clear the exit node" >&2
          exit 1
        '';
      };

      # Self-contained OpenCloud mount: school doesn't depend on the host's
      # krit.services.nas.opencloud-mount being enabled.
      services.davfs2.enable = true;
      services.davfs2.settings.globalSection = {
        use_locks = "0";
        gui_optimize = "1";
      };
      environment.etc."davfs2/secrets".source = config.sops.templates."davfs-secrets".path;
      users.users.${myUserName}.extraGroups = [ "davfs2" ];
      # OpenCloud is only reachable over the tailnet - force the full
      # myconfig.services.tailscale wrapper (not just the raw NixOS option),
      # so tailscale-autoconnect.service actually exists and authenticates,
      # regardless of whether the host enables this module by default.
      myconfig.services.tailscale.enable = lib.mkForce true;
      fileSystems = lib.listToAttrs (map mkSchoolOpencloudFileSystem schoolOpencloudSpaces);
      systemd.tmpfiles.rules = [
        "d /home/${myUserName}/.school-workspace 0700 ${myUserName} users -"
        "d ${schoolOpencloudMountPoint}/University 0700 ${myUserName} users -"
      ];

      # Self-contained virtualisation: school doesn't depend on the host's virtualisation.nix
      virtualisation.podman.enable = true;
      environment.systemPackages = with pkgs; [
        distrobox
        networkmanager-openconnect # For Cisco AnyConnect / GlobalProtect
        networkmanager-openvpn # For OpenVPN connections
        (pkgs.opencloud-desktop.overrideAttrs (old: {
          qtWrapperArgs = (old.qtWrapperArgs or [ ]) ++ [
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.kirigami.unwrapped}/lib/qt-6/qml"
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.qqc2-desktop-style}/lib/qt-6/qml"
            "--prefix"
            "NIXPKGS_QT6_QML_IMPORT_PATH"
            ":"
            "${pkgs.kdePackages.qqc2-breeze-style}/lib/qt-6/qml"
          ];
        }))
      ];

      # Configure allowed_signers for GPG SSH signing, and force git to use the school key and email
      home-manager.users.${myUserName} = { pkgs, lib, ... }: {
        nixpkgs.config.allowUnfree = true;

        home.activation.createSchoolDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/.school-workspace/oneDrive || true
          mkdir -p $HOME/.school-workspace/projects || true
          mkdir -p $HOME/.school-workspace/year/1st/1-semester || true
          mkdir -p $HOME/.school-workspace/year/1st/2-semester || true
          mkdir -p $HOME/.school-workspace/year/2st/3-semester || true
          mkdir -p $HOME/.school-workspace/year/2st/4-semester || true
          mkdir -p $HOME/.school-workspace/year/3st/5-semester || true
          mkdir -p $HOME/.school-workspace/year/3st/6-semester || true
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
          settings = {
            "github.com" = lib.mkForce {
              Hostname = "github.com";
              IdentityFile = "/home/${myUserName}/.ssh/id_school";
              IdentitiesOnly = "yes";
              PubkeyAuthentication = "yes";
            };

            "gitlab.com" = lib.mkForce {
              Hostname = "gitlab.com";
              IdentityFile = "/home/${myUserName}/.ssh/id_school";
              IdentitiesOnly = "yes";
            };
            "gitlab-edu.supsi.ch" = lib.mkForce {
              Hostname = "gitlab-edu.supsi.ch";
              IdentityFile = "/home/${myUserName}/.ssh/id_school";
              IdentitiesOnly = "yes";
            };
          };
        };

        # 🐚 Workspace Alias (shell-agnostic via home.shellAliases)
        home.shellAliases = {
          school = "cd ~/.school-workspace";
        };

        # On interactive shell start, check if distrobox tools are present
        programs.bash.initExtra = ''
          ${distroboxStartupCheck} 2>/dev/null
        '';

        home.packages = with pkgs; [
          # Required Tools
          mars-mips # MIPS simulator (tecnica digitale)
          geogebra6 # Dynamic mathematics software with graphics, algebra and spreadsheets

          # CS Tools (useful)
          dbeaver-bin
          insomnia
          wireshark
          zeal
          rclone
          filezilla
          libreoffice-qt

          # CS Notes / Cheat Sheets - shared toolchain (Typst/LaTeX/Pandoc, diagrams, PDF/image tooling, spellcheck)
          # from templates/krit/dev-environments/language-combined/{cs-notes,cs-cheat-sheets}/flake.nix
          typst
          typstyle
          tectonic
          pandoc
          haskellPackages.pandoc-crossref
          graphviz
          d2
          gnuplot
          poppler-utils
          ghostscript
          imagemagick
          qpdf
          librsvg
          inkscape
          jq
          hunspell
          hunspellDicts.en_US
          hunspellDicts.it_IT

          # CS Notes-specific extras (not in cs-cheat-sheets)
          tinymist
          plantuml
          mermaid-cli

          # CS Notes / Cheat Sheets - merged Python scientific/stats stack (union of both flakes)
          (python313.withPackages (ps: [
            ps.numpy
            ps.scipy
            ps.sympy
            ps.matplotlib
            ps.seaborn
            ps.pandas
            ps.statsmodels
            ps.scikit-learn
            ps.networkx
            ps.ipython
            ps.pygments
            ps.genanki
          ]))

          # Custom Shell Scripts
          (pkgs.writeShellScriptBin "brave-school" ''exec ${pkgs.brave}/bin/brave --user-data-dir=$HOME/.config/BraveSoftware/School "$@"'')
          (pkgs.makeDesktopItem {
            name = "brave-school";
            desktopName = "Brave (School)";
            exec = "brave-school %U";
            icon = "brave";
          })

          (pkgs.writeShellScriptBin "vscode-school" ''exec ${pkgs.vscode}/bin/code --ozone-platform=wayland --enable-features=WaylandWindowDecorations --user-data-dir=$HOME/.config/Code-School --extensions-dir=$HOME/.vscode-school/extensions "$@"'')
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
            exec ${pkgs.intellij-idea}/bin/intellij-idea "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "idea-school";
            desktopName = "IDEA (School)";
            exec = "idea-school";
            icon = "intellij-idea";
          })

          (pkgs.writeShellScriptBin "tkgate-school" ''
            ${pkgs.xhost}/bin/xhost +local: >/dev/null 2>&1
            export DISPLAY="''${DISPLAY:-:0}"

            # Xft.dpi lives in the X server's RESOURCE_MANAGER, shared by every
            # X11/Xwayland client on this DISPLAY (not just tkgate, and not
            # scoped to any one WM/compositor). Scope the override to this
            # invocation only: capture the current value, restore it on any
            # exit path (normal, error, or signal) via trap.
            origDpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | awk '/^Xft\.dpi:/{print $2}')
            origDpi="''${origDpi:-96}"
            restore_dpi() {
              ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: $origDpi" 2>/dev/null || true
            }
            trap restore_dpi EXIT INT TERM

            ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: ${xftDpi}" 2>/dev/null || true
            ${pkgs.distrobox}/bin/distrobox enter school-ubuntu -- bash -c '
              if ! command -v tkgate >/dev/null 2>&1; then
                echo "tkgate is not installed. Run: school-distrobox-setup"
                exit 1
              fi
              export DISPLAY="'"$DISPLAY"'"
              exec tkgate "$@"
            ' _ "$@"
          '')
          (pkgs.makeDesktopItem {
            name = "tkgate-school";
            desktopName = "tkGate (Ubuntu)";
            exec = "tkgate-school";
            icon = "tkgate";
          })

          (pkgs.writeShellScriptBin "sqldeveloper-school" ''
            ${pkgs.xhost}/bin/xhost +local: >/dev/null 2>&1
            exec ${pkgs.distrobox}/bin/distrobox enter school-arch -- bash -c '
              if [ ! -x /opt/sqldeveloper/sqldeveloper.sh ]; then
                echo "oracle-sqldeveloper is not installed. Run: school-distrobox-setup"
                exit 1
              fi
              export JAVA_HOME=/usr/lib/jvm/java-17-openjdk
              export _JAVA_AWT_WM_NONREPARENTING=1
              export JAVA_TOOL_OPTIONS="-Dsun.java2d.xrender=false -Dsun.java2d.uiScale=${guiScaleStr}"
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
                if distrobox enter ${app.container} -- bash -c '${app.check}' &>/dev/null; then
                  echo "    ${app.name} already installed, skipping."
                else
                  ${lib.optionalString (app ? rootInit) ''
                    echo "    Running rootInit in ${app.container}..."
                    ${pkgs.podman}/bin/podman exec --user root ${app.container} bash -c '${app.rootInit}' || true
                  ''}
                  ${lib.optionalString (app ? preInstall) ''
                    echo "    Installing dependencies in ${app.container}..."
                    distrobox enter ${app.container} -- bash -c '${app.preInstall}' || true
                  ''}
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

          # Nuclear cleanup: removes all school containers and the exported binaries.
          # Only reports what was actually removed - silent for things that didn't exist.
          (pkgs.writeShellScriptBin "school-distrobox-clear" ''
            set -uo pipefail
            REMOVED=""

            ${lib.concatMapStringsSep "\n" (app: ''
              if ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
                if ${pkgs.distrobox}/bin/distrobox rm "${app.container}" --force >/dev/null 2>&1; then
                  REMOVED="$REMOVED\n  - container: ${app.container}"
                fi
              fi
            '') distroboxApps}

            EXPORT_PATH="$HOME/.school-workspace/distrobox-bin"
            if [ -d "$EXPORT_PATH" ] && [ -n "$(ls -A "$EXPORT_PATH" 2>/dev/null)" ]; then
              FILES=$(ls -A "$EXPORT_PATH" | tr '\n' ' ')
              rm -rf "$EXPORT_PATH"/* "$EXPORT_PATH"/.[!.]* 2>/dev/null || true
              REMOVED="$REMOVED\n  - exported binaries in $EXPORT_PATH: $FILES"
            fi

            if [ -z "$REMOVED" ]; then
              echo "Nothing to clear - no school containers or exported binaries found."
            else
              echo -e "Removed:$REMOVED"
            fi
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
            Environment = [ "PATH=${lib.makeBinPath [ pkgs.rclone pkgs.coreutils ]}:/run/wrappers/bin" ]; # I-18: no literal $PATH
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
                exec = "brave-school --app=\"${url}\"";
                icon = icon;
                settings = {
                  StartupWMClass = startupClass;
                };
                terminal = false;
                type = "Application";
                categories = [ "Education" ];
                mimeType = [
                  "x-scheme-handler/https"
                  "x-scheme-handler/http"
                ];
              };
            };
          in
          builtins.listToAttrs [
            (makeSchoolPwa "SUPSI Portal" "https://portalestudenti.supsi.ch/" "education"
              "brave-portalestudenti.supsi.ch__-Default"
            )
            (makeSchoolPwa "iCorsi" "https://www.icorsi.ch/" "applications-education"
              "brave-www.icorsi.ch__-Default"
            )
            (makeSchoolPwa "School OpenCloud" "https://opencloud.nicolkrit.ch/" "folder-cloud"
              "brave-opencloud.nicolkrit.ch__-Default"
            )
            (makeSchoolPwa "NotebookLM" "https://notebooklm.google.com/" "utilities-terminal"
              "brave-notebooklm.google.com__-Default"
            )
            (makeSchoolPwa "USI Rooms" "https://usirooms.xyz/" "office-calendar" "brave-usirooms.xyz__-Default")
            (makeSchoolPwa "School OneDrive"
              "https://supsi-my.sharepoint.com/personal/kritpio_nicol_supsi_ch/_layouts/15/onedrive.aspx?sw=bypass&bypassReason=abandoned&startedResponseCatch=true"
              "folder-remote"
              "brave-supsi--my.sharepoint.com__-Default"
            )
            (makeSchoolPwa "Lecture Calendar"
              "https://calendar.google.com/calendar/u/0?cid=NDg0Zjg5MjUyOThlY2M0YzA2NWVkMTNhNGIwM2I4MjdlNTY0YWM5OWRlYjBjMDE0NThiNTZiOWY3MGY3ZmI5Y0Bncm91cC5jYWxlbmRhci5nb29nbGUuY29t"
              "x-office-calendar"
              "brave-calendar.google.com__-Default"
            )
          ];
      };
    };
  };
}
