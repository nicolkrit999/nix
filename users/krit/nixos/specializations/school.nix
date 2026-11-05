{ delib
, inputs
, config
, options
, lib
, pkgs
, ...
}:
let
  baseUserName = config.myconfig.constants.user;
  baseHome = config.users.users.${baseUserName}.home;
  schoolUserName = "krit-school";
  commonSecrets = ../../common/sops/krit-common-secrets-sops.yaml;
  c = config.myconfig.constants;
  term = c.terminal.name;
  scratchRule = class: {
    match.class = "^(${class})$";
    float = true;
    center = true;
    size = "80% 80%";
    workspace = "special:magic";
  };
  supsiPrinterUser = "SUPSI\\kritpio.nicol";
  schoolEmail = "kritpio.nicol@student.supsi.ch";
  schoolPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66";
  isLaptop = c.hostname == "nixos-laptop";
  sddmAssets = ../../src/sddm;
  dotfilesUrl = "https://github.com/nicolkrit999/dotfiles";

  # Absolute-path icons for the pinned PWAs: no icon theme ships a usable "education" or iCorsi icon.
  icorsiIcon = pkgs.fetchurl {
    name = "icorsi-icon.png";
    url = "https://www.icorsi.ch/apple-touch-icon.png";
    hash = "sha256-d3UXjEPypgsik8i0JuioMcLTAuTvU+MvPTFf7aroTQQ=";
  };
  supsiFavicon = pkgs.fetchurl {
    name = "supsi-favicon.ico";
    url = "https://www.supsi.ch/favicon.ico";
    hash = "sha256-NDrduWdN0Fq1HuGDuQPXV6elTR2WgS7mRUdeZDtb5cM=";
  };
  supsiIcon = pkgs.runCommand "supsi-icon.png" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    magick "${supsiFavicon}[5]" "png:$out"
  '';
  schoolBrave = "${pkgs.brave}/bin/brave";

  # HiDPI scale for the distrobox-launched X11/Java tools below (tkgate,
  # SQL Developer): the scale of the first enabled, non-mirrored Hyprland
  # monitor of the host. Static, not queried from the running compositor:
  # scale is a property of the panel, not of the active WM/DE.
  enabledMonitors = lib.filter
    (m: m.output != "" && !(m ? mirror) && (m.mode or "") != "disable")
    config.myconfig.programs.hyprland.monitors;
  guiScale = if enabledMonitors == [ ] then 1.0 else (lib.head enabledMonitors).scale or 1.0;
  guiScaleStr = toString guiScale;
  xftDpi = toString (builtins.floor (96 * guiScale));

  # Self-contained OpenCloud mount for the school user: only the University
  # spaces, mounted directly into ~/opencloud regardless of whether
  # krit.services.nas.opencloud-mount is enabled on the host. Reuses that
  # module's space list and the always-present "davfs-secrets" sops template
  # (see templates/krit/sops/service-wiring.nix).
  schoolOpencloudSpaces = lib.filter
    (space: lib.hasPrefix "University" space.path)
    config.myconfig.krit.services.nas.opencloud-mount.spaces;
  mkSchoolOpencloudFileSystem = { home, user, group }: space: {
    name = "${home}/opencloud/${space.path}";
    value = {
      device = space.url;
      fsType = "davfs";
      # davfs2 resolves names, so follow the user instead of a numeric uid.
      options = [
        "uid=${user}"
        "gid=${group}"
        "file_mode=0664"
        "dir_mode=0775"
        "_netdev"
        "nofail"
        "noauto"
        "x-systemd.automount"
      ];
    };
  };

  # enable = false only for options declared on this host: the personal layer
  # is not loaded everywhere (same approach as guest.nix kritOff).
  mkOff = paths: lib.foldl' lib.recursiveUpdate { } (
    map (path: lib.setAttrByPath ([ "myconfig" ] ++ path ++ [ "enable" ]) (lib.mkForce false)) (
      lib.filter (path: lib.hasAttrByPath ([ "myconfig" ] ++ path) options) paths
    )
  );

  personalOff = mkOff [
    [ "krit" "home" "base" ]
    [ "krit" "programs" "dolphin" ]
    [ "krit" "programs" "proton-cli" ]
    [ "krit" "programs" "pwas" ]
    [ "krit" "services" "cloud" "googleDrive" ]
    [ "krit" "services" "cloud" "onedrivePersonal" ]
    [ "krit" "services" "cloud" "pcloud" ]
    [ "krit" "services" "cloud" "protonDrive" ]
    [ "krit" "services" "desktop" "flatpak" ]
    [ "krit" "services" "desktop" "local-packages" ]
    [ "krit" "services" "laptop" "flatpak" ]
    [ "krit" "services" "laptop" "local-packages" ]
    [ "krit" "services" "nas" "desktop-borg-backup" ]
    [ "krit" "services" "nas" "laptop-borg-backup" ]
    [ "krit" "services" "nas" "opencloud-mount" ]
    [ "krit" "services" "nas" "smb" ]
    [ "krit" "services" "nas" "sshfs" ]
    [ "krit" "services" "network-tools" ]
    [ "krit" "services" "windows-mount" ]
    [ "krit" "system" "ssh-config" ]
    [ "programs" "concord" ]
    [ "programs" "npm" ]
    [ "programs" "openlogi" ]
    [ "programs" "prismlauncher" ]
    [ "programs" "thunderbird" ]
    [ "programs" "zapfast" ]
    [ "services" "external" "dotfiles-private" ]
    [ "services" "snapshots" ]
  ];

  # Hyprland and KDE Plasma are the only desktops offered to the school user.
  desktopsOff = mkOff [
    [ "programs" "caelestia" ]
    [ "programs" "cosmic" ]
    [ "programs" "gnome" ]
    [ "programs" "mango" ]
    [ "programs" "niri" ]
    [ "programs" "noctalia" ]
    [ "programs" "waybar-mango" ]
    [ "programs" "waybar-niri" ]
  ];

  # Resolves the SQL Developer RPM on the OpenCloud General space (never stored in the repo, Oracle licence).
  # Runs on the host: prints the RPM path on stdout, diagnostics on stderr.
  # Exit codes: 0 found, 10 General space not mounted (RPM state unknown), 11 mounted but no RPM.
  # Overrides for tests: SCHOOL_OPENCLOUD_GENERAL_DIR, SCHOOL_RPM_MOUNT_TRIES, SCHOOL_RPM_MOUNT_SLEEP.
  sqlDeveloperRpmResolve = pkgs.writeShellScript "school-sqldeveloper-rpm-resolve" ''
    dir="${"$"}{SCHOOL_OPENCLOUD_GENERAL_DIR:-$HOME/opencloud/University/0001-General}"
    tries="${"$"}{SCHOOL_RPM_MOUNT_TRIES:-20}"
    nap="${"$"}{SCHOOL_RPM_MOUNT_SLEEP:-3}"

    # The systemd automount fires on access; autofs alone does not count, a real filesystem must sit on top.
    mounted() {
      ${pkgs.util-linux}/bin/findmnt -rn -o FSTYPE --mountpoint "$dir" 2>/dev/null | ${pkgs.gnugrep}/bin/grep -qvx autofs
    }

    i=0
    while [ "$i" -lt "$tries" ]; do
      ${pkgs.coreutils}/bin/ls "$dir" >/dev/null 2>&1 || true
      mounted && break
      i=$((i + 1))
      [ "$i" -lt "$tries" ] && ${pkgs.coreutils}/bin/sleep "$nap"
    done

    if ! mounted; then
      unit=$(${pkgs.systemd}/bin/systemd-escape -p --suffix=automount "$dir")
      echo "OpenCloud General space is not mounted (tailscale up? sudo systemctl status $unit)" >&2
      exit 10
    fi

    for rpm in "$dir"/software/oracle-sql-developer/sqldeveloper-*.noarch.rpm; do
      if [ -e "$rpm" ]; then
        echo "$rpm"
        exit 0
      fi
    done

    echo "sqldeveloper-*.noarch.rpm not found. Download it from:" >&2
    echo "  https://www.oracle.com/database/sqldeveloper/technologies/download/" >&2
    echo "and upload it to the General space in OpenCloud under software/oracle-sql-developer/" >&2
    exit 11
  '';

  # Copies a host file to a plain file under $HOME and prints the copy's path on stdout. The davfs
  # automount under $HOME is not visible inside the distrobox container (only the underlying home
  # bind mount is), so installers read from this staged copy instead. The copy goes to a temp name
  # and is renamed only when complete; an existing complete copy (same size) is reused.
  # Overrides for tests: SCHOOL_STAGE_DIR, SCHOOL_STAGE_MARGIN_BYTES.
  schoolStageFile = pkgs.writeShellScript "school-stage-file" ''
    set -u
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    src="''${1:-}"
    dir="''${SCHOOL_STAGE_DIR:-$HOME/.cache/school-distrobox}"
    margin="''${SCHOOL_STAGE_MARGIN_BYTES:-104857600}"

    if [ -z "$src" ] || [ ! -f "$src" ]; then
      echo "school-stage-file: not a readable file: $src" >&2
      exit 1
    fi
    mkdir -p -- "$dir" || { echo "school-stage-file: cannot create $dir" >&2; exit 1; }
    base=$(basename -- "$src")
    dest="$dir/$base"
    size=$(stat -c %s -- "$src") || exit 1

    if [ -f "$dest" ] && [ ! -L "$dest" ] && [ "$(stat -c %s -- "$dest")" = "$size" ]; then
      echo "$dest"
      exit 0
    fi

    avail=$(df --output=avail -B1 -- "$dir" | tail -n 1 | tr -d ' ')
    need=$((size + margin))
    if [ "$avail" -lt "$need" ]; then
      echo "school-stage-file: not enough free space in $dir: need $((need / 1048576)) MiB, have $((avail / 1048576)) MiB. Free some space under $HOME and run again." >&2
      exit 1
    fi

    tmp="$dir/.$base.part.$$"
    trap 'rm -f -- "$tmp"' EXIT
    trap 'exit 130' INT
    trap 'exit 143' TERM
    echo "Staging $base ($((size / 1048576)) MiB) in $dir for the container..." >&2
    cp -- "$src" "$tmp" || { echo "school-stage-file: copy of $src failed" >&2; exit 1; }
    if [ "$(stat -c %s -- "$tmp")" != "$size" ]; then
      echo "school-stage-file: incomplete copy of $src" >&2
      exit 1
    fi
    mv -f -- "$tmp" "$dest" || exit 1
    echo "$dest"
  '';

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
      # Resolved on the host before entering the container, then staged to a plain file under $HOME
      # (the davfs mount is not visible in the container); $1 is the staged RPM path.
      hostArg = sqlDeveloperRpmResolve;
      hostStage = schoolStageFile;
      install = builtins.concatStringsSep "\n" [
        ''[ -n "$1" ] || exit 1''
        ''[ -r "$1" ] || { echo "cannot read $1 inside the container" >&2; exit 1; }''
        ''sudo bsdtar -xf "$1" -C /''
      ];
      postInstall = builtins.concatStringsSep "\n" [
        "sudo chmod +x /opt/sqldeveloper/sqldeveloper.sh"
        # Pre-configure JDK path so sqldeveloper.sh doesn't prompt interactively on first run
        "sudo sed -i 's|^#\\?SetJavaHome.*|SetJavaHome /usr/lib/jvm/java-17-openjdk|' /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf 2>/dev/null || true"
        "grep -q 'SetJavaHome' /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf 2>/dev/null || echo 'SetJavaHome /usr/lib/jvm/java-17-openjdk' | sudo tee -a /opt/sqldeveloper/sqldeveloper/bin/sqldeveloper.conf >/dev/null"
      ];
    }
  ];

  # Per-app install steps of school-distrobox-setup. An app with hostArg first runs that command
  # on the host (before `distrobox enter`) and passes its stdout into the container command as
  # ONE argument ($1); exit code 10 means "cannot tell yet" and is reported as blocked, not as failed.
  # With hostStage the resolved path is first copied to a plain file under $HOME (STAGED_FILE, removed
  # after the install and by the EXIT trap of the setup script) and that copy becomes $1.
  distroboxInstallSteps = app:
    let
      enter = script: "${pkgs.distrobox}/bin/distrobox enter ${app.container} -- bash -c ${lib.escapeShellArg script}";
      steps = ''
        ${lib.optionalString (app ? rootInit) ''
          echo "    Running rootInit in ${app.container}..."
          ${pkgs.podman}/bin/podman exec --user root ${app.container} bash -c ${lib.escapeShellArg app.rootInit} || true
        ''}
        ${lib.optionalString (app ? preInstall) ''
          echo "    Installing dependencies in ${app.container}..."
          ${enter app.preInstall} || true
        ''}
        echo "    Installing ${app.name}..."
        if ! ${enter app.install}${lib.optionalString (app ? hostArg) " _ \"$HOST_ARG\""}; then
          echo "    FAILED to install ${app.name}"
          FAILURES=$((FAILURES + 1))
        else
          ${lib.optionalString (app ? postInstall) ''
            ${enter app.postInstall} || true
          ''}
          echo "    ${app.name} installed."
        fi
      '';
    in
    if app ? hostArg then ''
      host_rc=0
      HOST_ARG=$(${app.hostArg}) || host_rc=$?
      if [ "$host_rc" -eq 10 ]; then
        echo "    Cannot install ${app.name}: OpenCloud is not mounted, nothing was installed."
        BLOCKED=$((BLOCKED + 1))
      elif [ "$host_rc" -ne 0 ]; then
        echo "    FAILED to install ${app.name}"
        FAILURES=$((FAILURES + 1))
      else
        ${if app ? hostStage then ''
          stage_rc=0
          STAGED_FILE=$(${app.hostStage} "$HOST_ARG") || stage_rc=$?
          if [ "$stage_rc" -ne 0 ]; then
            STAGED_FILE=""
            echo "    FAILED to stage the installer for ${app.name} under $HOME"
            FAILURES=$((FAILURES + 1))
          else
            HOST_ARG="$STAGED_FILE"
            ${steps}
            cleanup_staged
          fi
        '' else steps}
      fi
    '' else steps;

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
    MISSING=""
    ${lib.concatMapStringsSep "\n" (app: ''
      if ! ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
        MISSING="$MISSING ${app.name}(no container)"
      elif ! ${pkgs.distrobox}/bin/distrobox enter ${app.container} -- bash -c ${lib.escapeShellArg app.check} &>/dev/null; then
        MISSING="$MISSING ${app.name}(not installed)"
      fi
    '') distroboxApps}

    # The RPM is only relevant while SQL Developer is not installed yet. The helper prints the
    # upload hint itself; an unmounted General space is never reported as a missing RPM.
    if [[ "$MISSING" == *oracle-sqldeveloper* ]]; then
      ${sqlDeveloperRpmResolve} >/dev/null
      rc=$?
      if [ "$rc" -eq 10 ]; then
        echo "oracle-sqldeveloper: cannot verify the RPM: opencloud not mounted"
      fi
    fi

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
    specialisation.school.configuration = { config, ... }:
      let
        user = config.myconfig.constants.user;
        home = config.users.users.${user}.home;
        group = config.users.users.${user}.group;
        schoolKey = "${home}/.ssh/id_school";
      in
      {
        system.nixos.tags = [ "school" ];

        # Declared only in this specialisation so ~/.ssh/id_school does not exist in the base system or other specialisations.
        sops.secrets.school_ssh_key = {
          sopsFile = commonSecrets;
          owner = user;
          path = schoolKey;
        };
        sops.secrets.school_ssh_pub = {
          sopsFile = commonSecrets;
          owner = user;
          path = "${schoolKey}.pub";
        };
        # Must exist in krit-common-secrets-sops.yaml at build time: the sops-nix manifest check fails the build without it.
        sops.secrets.rclone_school_onedrive_conf = {
          sopsFile = commonSecrets;
          owner = user;
        };

        myconfig = {
          krit = {
            system.git-ssh-signing = {
              signingKey = lib.mkForce schoolKey;
              allowedSignersEmail = lib.mkForce schoolEmail;
              allowedSignersPubKey = lib.mkForce schoolPubKey;
              extraAllowedSigners = lib.mkForce [ ];
            };

            commonSopsSecrets.personalSecrets = lib.mkForce false;
            programs.zen-browser.universityOnly = lib.mkForce true;

            # The school workspace is the whole home: Calendar and Gmail stay enabled in every claude project below it.
            programs.claude-code-wrappers.connectorWorkspaces = [ "" ];

            # Go-to keys: drop the ones whose target does not exist for krit-school (gn flake dir, gP dev-environments, gm /mnt), add the school layout.
            programs.yazi = {
              goToExclude = [ "n" "P" "m" ];
              goToExtra = [
                { on = [ "g" "o" ]; run = "cd ~/opencloud"; desc = "Go ~/opencloud"; }
                { on = [ "g" "O" ]; run = "cd ~/oneDrive"; desc = "Go ~/oneDrive"; }
                { on = [ "g" "P" ]; run = "cd ~/Projects"; desc = "Go ~/Projects"; }
                { on = [ "g" "y" ]; run = "cd ~/Documents/year"; desc = "Go ~/Documents/year"; }
                { on = [ "g" "T" ]; run = "cd ~/Templates"; desc = "Go ~/Templates"; }
                { on = [ "g" "S" ]; run = "cd ~/Public"; desc = "Go ~/Public"; }
              ];
            };
          };

          services = {
            # Replaces the personal dotfiles-private mapping (disabled below); the public ~/dotfiles clone has no wallpapers repo.
            external.dotfiles.wallpapersLink = lib.mkForce false;

            # OpenCloud is only reachable over the tailnet - force the full
            # myconfig.services.tailscale wrapper (--operator, firewall trust/rpfilter,
            # exit-node helpers), not just the raw NixOS option. Login is upstream
            # tailscaled-autoconnect via authKeyFile (templates/krit/sops/service-wiring.nix).
            tailscale.enable = lib.mkForce true;

            rcloneMount = {
              enable = lib.mkForce true;
              mounts = [
                {
                  name = "school-onedrive";
                  remote = "school-onedrive:";
                  configFile = config.sops.secrets.rclone_school_onedrive_conf.path;
                  mountPoint = "${home}/oneDrive";
                }
              ];
            };

            sddm-astronaut.assetsDir = sddmAssets;
            sddm-pixie.assetsDir = sddmAssets;
          };

          # Replace the default profile autostart
          programs = {
            kde.enable = lib.mkForce true;

            # The host pins personal apps that are not installed here; only desktop ids present in this generation.
            kde.pinnedApps = lib.mkForce [
              "zen-beta.desktop"
              "${term}.desktop"
              "yazi.desktop"
              "custom-nvim.desktop"
              "school-pwa-icorsi.desktop"
              "school-pwa-supsi-portal.desktop"
              "code.desktop"
              "intellij-idea.desktop"
              "com.obsproject.Studio.desktop"
              "LocalSend.desktop"
            ];

            hyprland.execOnce = lib.mkForce (
              if c.hostname == "nixos-desktop" then
                [
                  "[workspace 2 silent] ${term} --class nvim-school -d $HOME -e nvim"
                  "[workspace 3 silent] ${term} --class yazi -d $HOME -e yazi"
                  "[workspace 7 silent] ${schoolBrave} --app=https://www.icorsi.ch/"
                  "[workspace 8 silent] ${term} -d $HOME"
                ]
              else if isLaptop then
                [
                  "[workspace 2 silent] ${term} --class nvim-school -d $HOME -e nvim"
                  "[workspace 3 silent] ${term} --class yazi -d $HOME -e yazi"
                  "[workspace 4 silent] ${term} -d $HOME"
                  "[workspace 5 silent] ${schoolBrave} --app=https://www.icorsi.ch/"
                ]
              else
                [ ]
            );
            # Workspace rules stay cleared; only the scratch rules (same as scratchRule in hosts/*/default.nix) are kept.
            hyprland.windowRules = lib.mkForce (map scratchRule [
              "scratch-term"
              "scratch-fs"
              "scratch-browser"
            ]);
          };

          # Override host-default constants for school specialization
          constants = {
            user = lib.mkForce schoolUserName;
            browser = lib.mkForce "zen-beta";
            editor = lib.mkForce "nvim";
            fileManager = lib.mkForce "yazi";
            shell = lib.mkForce "bash";
          };

          # The host sets Flatpak app ids that are not installed here (local-packages is off).
          mime = {
            docEditor = lib.mkForce "libreoffice";
            sheetEditor = lib.mkForce "libreoffice";
            slideEditor = lib.mkForce "libreoffice";
          };
        };

        # Force exit-node off on every boot into this specialisation, regardless
        # of whatever exit-node state tailscale persisted from the last boot.
        # Type=exec so it never blocks boot; tailscale set works on prefs while
        # logged out, so retrying the set itself also covers booting offline.
        systemd.services.tailscale-school-exit-node-off = {
          description = "Force tailscale exit-node off for the school specialisation";
          after = [
            "tailscaled.service"
            "tailscaled-set.service"
            "tailscaled-autoconnect.service"
          ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];

          path = [ config.services.tailscale.package ];

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
        # Same davfs2 settings and secrets file as the base opencloud mount, defined here too so school stays independent of it; the values must stay equal.
        environment.etc."davfs2/secrets".source = config.sops.templates."davfs-secrets".path;
        fileSystems = lib.listToAttrs (map (mkSchoolOpencloudFileSystem { inherit home user group; }) schoolOpencloudSpaces);
        systemd.tmpfiles.rules = [
          "d ${home} ${config.users.users.${user}.homeMode} ${user} ${group} -"
          "d ${home}/opencloud 0700 ${user} ${group} -"
          "d ${home}/opencloud/University 0700 ${user} ${group} -"
          "d ${home}/.ssh 0700 ${user} ${group} -"
        ];

        # GitHub's published ed25519 host key, so a first `git clone git@github.com:...` needs no TOFU prompt (also works without a tty).
        programs.ssh.knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

        # Dedicated account: fixed uid and its own subuid/subgid range next to the personal user's.
        users.users.${user} = {
          uid = lib.mkForce 1001;
          subUidRanges = lib.mkForce [{ startUid = 165536; count = 65536; }];
          subGidRanges = lib.mkForce [{ startGid = 165536; count = 65536; }];
          extraGroups = [ "davfs2" "wireshark" ];
        };

        # Copies the school Claude skills/agents/commands/MCP config from the personal
        # user's dotfiles-private checkout; the school user has no clone of its own.
        # --delete only ever applies inside the three managed directories.
        systemd.services.school-claude-sync = {
          description = "Copy the school Claude config from dotfiles-private";
          wantedBy = [ "multi-user.target" ];
          after = [ "local-fs.target" ];
          path = [ pkgs.coreutils pkgs.rsync ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            src=${lib.escapeShellArg "${baseHome}/dotfiles-private/claude/school"}
            dst=${lib.escapeShellArg home}
            if [ ! -d "$src" ]; then
              echo "school-claude-sync: $src is missing, nothing to copy" >&2
              exit 0
            fi
            install -d -m 0755 -o ${user} -g ${group} "$dst/.claude"
            for d in skills agents commands; do
              if [ -d "$src/.claude/$d" ]; then
                install -d -m 0755 -o ${user} -g ${group} "$dst/.claude/$d"
                rsync -rLt --delete --chown=${user}:${group} "$src/.claude/$d/" "$dst/.claude/$d/" \
                  || echo "school-claude-sync: copying $d failed" >&2
              fi
            done
            if [ -f "$src/.mcp.json" ]; then
              install -m 0644 -o ${user} -g ${group} "$src/.mcp.json" "$dst/.mcp.json" \
                || echo "school-claude-sync: copying .mcp.json failed" >&2
            fi
            exit 0
          '';
        };

        # Self-contained virtualisation: school doesn't depend on the host's virtualisation.nix
        virtualisation.podman.enable = true;
        networking.networkmanager.plugins = with pkgs; [
          networkmanager-openconnect # Cisco AnyConnect / GlobalProtect
          networkmanager-openvpn
        ];

        # Packet capture for the wireshark group (same package as krit.services.network-tools).
        programs.wireshark = {
          enable = true;
          package = lib.mkDefault pkgs.wireshark;
        };

        # SUPSI Follow Me printing. smbspool (CUPS smb backend, linked in by services.printing)
        # refuses to run without /etc/samba/smb.conf and needs SMB2. The login is
        # SUPSI\<user> without @supsi.ch. No Sharp MX-4110FN PPD exists in nixpkgs, so the
        # generic PostScript driver is used. ensurePrinters cannot read a secret, hence the
        # oneshot builds the device URI from the sops password at runtime (lpadmin takes it in
        # argv, briefly visible in /proc) and krit-printer-default picks the default (DTI_PRINTERS while printers.supsi.ch answers on 445, else the home printer).
        imports = [
          personalOff
          desktopsOff
          (lib.mkIf isLaptop {
            sops.secrets.school_supsi_password = {
              sopsFile = commonSecrets;
              owner = "root";
              mode = "0400";
            };
            services.printing.enable = true;
            myconfig.krit.services.printing = {
              fallbackPrinter = "DTI_PRINTERS";
              fallbackProbeHost = "printers.supsi.ch";
            };
            environment.etc."samba/smb.conf".text = ''
              [global]
              client min protocol = SMB2
            '';
            systemd.services.supsi-printer-setup = {
              description = "Register the SUPSI Follow Me printer queue";
              wantedBy = [ "multi-user.target" ];
              after = [ "cups.service" ];
              requires = [ "cups.service" ];
              restartTriggers = [ config.environment.etc."samba/smb.conf".source ];
              path = [ config.services.printing.package ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
                PrivateTmp = true;
                ExecStart = pkgs.writeShellScript "supsi-printer-setup" ''
                  uri=$(${pkgs.python3}/bin/python3 -I -c '
                  import sys, urllib.parse as u
                  q = lambda s: u.quote(s, safe="")
                  pw = open(sys.argv[1]).read().rstrip("\n")
                  print("smb://" + q(sys.argv[2]) + ":" + q(pw) + "@printers.supsi.ch/DTI_PRINTERS")
                  ' ${config.sops.secrets.school_supsi_password.path} ${lib.escapeShellArg supsiPrinterUser})
                  lpadmin -p DTI_PRINTERS -E -v "$uri" \
                    -m drv:///sample.drv/generic.ppd -o printer-is-shared=false
                  ${config.systemd.package}/bin/systemctl start --no-block krit-printer-default.service || true
                '';
              };
            };
          })
        ];
        # No opencloud-desktop sync client on purpose: the spaces are already mounted over
        # davfs2 above, and a second writer (own sync folder, own credentials) on the same
        # spaces risks conflicting uploads and deletions. The web UI stays as a PWA.
        environment.systemPackages = [ pkgs.distrobox ];

        # School user environment: workspace, git/ssh identity, tools, OneDrive mount, web apps
        home-manager.users.${user} = { pkgs, lib, ... }: {
          # null drops XDG_MUSIC_DIR and the ~/Music creation (xdg.userDirs.createDirectories); an existing ~/Music is left alone.
          xdg.userDirs.music = null;

          home = {
            # "|| true": under set -eu a stale rclone FUSE mountpoint (oneDrive) would otherwise abort the activation
            # ~/Projects comes from xdg.userDirs (createDirectories); ~/Documents/year is the school layout.
            activation.createSchoolDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              run mkdir -p ${lib.concatMapStringsSep " " (d: "\"$HOME/${d}\"") [
                ".learning"
                "Documents/year/1st/1-semester"
                "Documents/year/1st/2-semester"
                "Documents/year/2nd/3-semester"
                "Documents/year/2nd/4-semester"
                "Documents/year/3rd/5-semester"
                "Documents/year/3rd/6-semester"
                "momentary"
                "distrobox-bin"
              ]} || true
            '';

            # Old layout leftovers: rmdir only, bottom-up. rmdir refuses non-empty directories, mountpoints and symlinks, so nothing is ever deleted recursively.
            activation.removeEmptySchoolLeftovers = lib.hm.dag.entryAfter [ "createSchoolDirs" ] ''
              for d in ${lib.concatMapStringsSep " " (d: "\"$HOME/${d}\"") [
                "year/1st/1-semester"
                "year/1st/2-semester"
                "year/2nd/3-semester"
                "year/2nd/4-semester"
                "year/3rd/5-semester"
                "year/3rd/6-semester"
                "year/1st"
                "year/2nd"
                "year/3rd"
                "year"
                "projects"
              ]}; do
                ${pkgs.coreutils}/bin/rmdir -- "$d" 2>/dev/null || true
              done
            '';

            # School distrobox exports go to isolated path (not ~/.distrobox-bin)
            sessionPath = [ "$HOME/distrobox-bin" ];

            shellAliases = {
              school = "cd ~";
            };

            packages = with pkgs; [
              # Screen sharing / recording (the host local-packages module is off in this specialisation)
              obs-studio

              # Unwrapped: krit-school has its own home, no profile isolation needed
              brave
              intellij-idea
              proton-pass
              vscode

              # Picked from the host local-packages list (that module is off here)
              drawio
              pay-respects
              tealdeer
              teams-for-linux

              # Required Tools
              mars-mips # MIPS simulator (tecnica digitale)
              geogebra6 # Dynamic mathematics software with graphics, algebra and spreadsheets

              # CS Tools (useful)
              anki
              dbeaver-bin
              filezilla
              insomnia
              libreoffice-qt
              rclone
              zeal

              # moodle-dl GUI (upstream master pin; unreleased, nixpkgs lacks it); see memory project_moodle_dl_gui_master_pin.md
              (moodle-dl.overridePythonAttrs (old: {
                version = "2.4.0-unstable-2026-06-20";
                src = fetchFromGitHub {
                  owner = "C0D3D3V";
                  repo = "Moodle-DL";
                  rev = "d88b2343f4a54a21404335648bd0c459853fa587";
                  hash = "sha256-y+cW1xlr4rt4euAMOZnIkyrmbDxlHP+D2+0J9PprW8o=";
                };
                build-system = [ python3Packages.hatchling ];
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ qt6.wrapQtAppsHook ];
                buildInputs = (old.buildInputs or [ ]) ++ [ qt6.qtwayland ];
                dependencies = old.dependencies ++ [ python3Packages.pyside6 ];
                dontWrapQtApps = true;
                preFixup = (old.preFixup or "") + ''
                  makeWrapperArgs+=("''${qtWrapperArgs[@]}")
                '';
              }))
              (makeDesktopItem {
                name = "moodle-dl-gui";
                desktopName = "Moodle-DL";
                exec = "moodle-dl --gui";
                icon = "folder-download";
                categories = [ "Education" "Network" ];
              })

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
              (writeShellScriptBin "tkgate-school" ''
                export DISPLAY="''${DISPLAY:-:0}"
                xhostEntry="si:localuser:$(${pkgs.coreutils}/bin/id -un)"
                ${pkgs.xhost}/bin/xhost "+$xhostEntry" >/dev/null 2>&1

                # Xft.dpi lives in the X server's RESOURCE_MANAGER, shared by every
                # X11/Xwayland client on this DISPLAY (not just tkgate, and not
                # scoped to any one WM/compositor). Scope the override to this
                # invocation only: capture the current value, restore it on any
                # exit path (normal, error, or signal) via trap; the same trap
                # revokes the X access granted above.
                origDpi=$(${pkgs.xrdb}/bin/xrdb -query 2>/dev/null | awk '/^Xft\.dpi:/{print $2}')
                origDpi="''${origDpi:-96}"
                cleanup() {
                  ${pkgs.xrdb}/bin/xrdb -merge <<< "Xft.dpi: $origDpi" 2>/dev/null || true
                  ${pkgs.xhost}/bin/xhost "-$xhostEntry" >/dev/null 2>&1 || true
                }
                trap cleanup EXIT INT TERM

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
              (makeDesktopItem {
                name = "tkgate-school";
                desktopName = "tkGate (Ubuntu)";
                exec = "tkgate-school";
                icon = "tkgate";
              })

              (writeShellScriptBin "sqldeveloper-school" ''
                xhostEntry="si:localuser:$(${pkgs.coreutils}/bin/id -un)"
                ${pkgs.xhost}/bin/xhost "+$xhostEntry" >/dev/null 2>&1
                trap '${pkgs.xhost}/bin/xhost "-$xhostEntry" >/dev/null 2>&1 || true' EXIT INT TERM
                ${pkgs.distrobox}/bin/distrobox enter school-arch -- bash -c '
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
              (makeDesktopItem {
                name = "sqldeveloper-school";
                desktopName = "SQL Developer (School)";
                exec = "sqldeveloper-school";
                icon = "oracle-sqldeveloper";
              })

              # Idempotent setup: creates containers and installs only what's missing.
              (writeShellScriptBin "school-distrobox-setup" ''
                set -uo pipefail
                EXPORT_PATH="$HOME/distrobox-bin"
                mkdir -p "$EXPORT_PATH"
                FAILURES=0
                BLOCKED=0
                STAGED_FILE=""

                # Only ever removes the staged copy (a plain file under ~/.cache/school-distrobox), never the OpenCloud original.
                cleanup_staged() {
                  if [ -n "$STAGED_FILE" ] && [ -f "$STAGED_FILE" ] && [ ! -L "$STAGED_FILE" ]; then
                    ${pkgs.coreutils}/bin/rm -f -- "$STAGED_FILE"
                    ${pkgs.coreutils}/bin/rmdir -- "$(${pkgs.coreutils}/bin/dirname -- "$STAGED_FILE")" 2>/dev/null || true
                  fi
                  STAGED_FILE=""
                }
                trap cleanup_staged EXIT
                trap 'exit 130' INT
                trap 'exit 143' TERM

                container_exists() { ${pkgs.podman}/bin/podman container exists "$1" 2>/dev/null; }

                ${lib.concatMapStringsSep "\n\n" (app: ''
                  # --- ${app.name} in ${app.container} ---
                  echo "==> Checking ${app.name}..."
                  if ! container_exists "${app.container}"; then
                    echo "    Creating ${app.container}..."
                    if ! ${pkgs.distrobox}/bin/distrobox create --name "${app.container}" --image "${app.image}" --yes; then
                      echo "    FAILED to create ${app.container}"
                      FAILURES=$((FAILURES + 1))
                    fi
                  fi
                  if container_exists "${app.container}"; then
                    if ${pkgs.distrobox}/bin/distrobox enter ${app.container} -- bash -c ${lib.escapeShellArg app.check} &>/dev/null; then
                      echo "    ${app.name} already installed, skipping."
                    else
                      ${distroboxInstallSteps app}
                    fi
                  fi
                '') distroboxApps}

                if [ "$FAILURES" -gt 0 ]; then
                  echo ""
                  echo "==> $FAILURES tool(s) failed to provision."
                  exit 1
                fi
                if [ "$BLOCKED" -gt 0 ]; then
                  echo ""
                  echo "==> $BLOCKED tool(s) could not be provisioned: OpenCloud is not mounted. Run again once it is."
                  exit 3
                fi
                echo ""
                echo "==> All school distrobox tools are ready."
              '')

              # Deep check: verifies packages are actually installed inside containers
              (writeShellScriptBin "school-distrobox-check" ''
                exec ${distroboxDeepCheck}
              '')

              # Nuclear cleanup: removes all school containers and the exported binaries.
              # Only reports what was actually removed - silent for things that didn't exist.
              (writeShellScriptBin "school-distrobox-clear" ''
                set -uo pipefail
                REMOVED=""

                ${lib.concatMapStringsSep "\n" (app: ''
                  if ${pkgs.podman}/bin/podman container exists "${app.container}" 2>/dev/null; then
                    if ${pkgs.distrobox}/bin/distrobox rm "${app.container}" --force >/dev/null 2>&1; then
                      REMOVED="$REMOVED\n  - container: ${app.container}"
                    fi
                  fi
                '') distroboxApps}

                EXPORT_PATH="$HOME/distrobox-bin"
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
          };

          # Signing key and allowed_signers come from krit.system.git-ssh-signing (set above);
          # signByDefault additionally enables tag.gpgSign.
          programs = {
            git = {
              settings = {
                user.email = lib.mkForce schoolEmail;
                user.name = lib.mkForce "Krit Pio Nicol-University";
                commit.gpgSign = lib.mkForce true;
              };
              signing.signByDefault = true;
            };

            # SSH: the school identity for the git hosts used at school
            ssh = {
              enable = true;
              enableDefaultConfig = lib.mkForce false;
              settings = {
                "github.com" = lib.mkForce {
                  Hostname = "github.com";
                  IdentityFile = schoolKey;
                  IdentitiesOnly = "yes";
                };

                "gitlab.com" = lib.mkForce {
                  Hostname = "gitlab.com";
                  IdentityFile = schoolKey;
                  IdentitiesOnly = "yes";
                };
                "gitlab-edu.supsi.ch" = lib.mkForce {
                  Hostname = "gitlab-edu.supsi.ch";
                  IdentityFile = schoolKey;
                  IdentitiesOnly = "yes";
                };
              };
            };

            # On interactive shell start, check if distrobox tools are present
            bash.initExtra = ''
              ${distroboxStartupCheck} 2>/dev/null
            '';
          };

          # The mount unit itself comes from myconfig.services.rcloneMount (set above); stop retrying after repeated failures.
          systemd.user.services = {
            rclone-mount-school-onedrive.Unit = {
              StartLimitIntervalSec = 300;
              StartLimitBurst = 5;
            };

            # Clones the public dotfiles once, only when ~/dotfiles is missing; never pulls, resets or deletes anything.
            # The clone lands in a temporary directory first so an interrupted run cannot leave a half-cloned ~/dotfiles.
            school-dotfiles-clone = {
              Unit = {
                Description = "Clone the public dotfiles into ~/dotfiles if missing";
                ConditionPathExists = "!%h/dotfiles";
                StartLimitIntervalSec = 0;
              };
              Install.WantedBy = [ "default.target" ];
              Service = {
                Type = "oneshot";
                Restart = "on-failure";
                RestartSec = "30s";
                Environment = [
                  "GIT_TERMINAL_PROMPT=0"
                  "GIT_SSL_CAINFO=/etc/ssl/certs/ca-certificates.crt"
                ];
                ExecStart = pkgs.writeShellScript "school-dotfiles-clone" ''
                  set -eu
                  [ -e "$HOME/dotfiles" ] && exit 0
                  tmp=$(${pkgs.coreutils}/bin/mktemp -d "$HOME/.dotfiles-clone.XXXXXX")
                  trap '${pkgs.coreutils}/bin/rm -rf "$tmp"' EXIT
                  ${pkgs.git}/bin/git clone --quiet ${dotfilesUrl} "$tmp/dotfiles"
                  [ -e "$HOME/dotfiles" ] || ${pkgs.coreutils}/bin/mv "$tmp/dotfiles" "$HOME/dotfiles"
                '';
              };
            };
          };

          xdg.desktopEntries =
            let
              makeSchoolPwa = name: url: icon: startupClass: {
                name = "school-pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
                value = {
                  inherit name icon;
                  genericName = "School Web App";
                  comment = "Launch ${name}";
                  exec = "${schoolBrave} --app=\"${url}\"";
                  settings = {
                    StartupWMClass = startupClass;
                  };
                  categories = [ "Education" ];
                };
              };
            in
            builtins.listToAttrs [
              (makeSchoolPwa "SUPSI Portal" "https://portalestudenti.supsi.ch/" "${supsiIcon}"
                "brave-portalestudenti.supsi.ch__-Default"
              )
              (makeSchoolPwa "iCorsi" "https://www.icorsi.ch/" "${icorsiIcon}"
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
