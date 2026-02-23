{ delib
, inputs
, pkgs
, ...
}:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # 🌟 CORE APPS & THEME
  myBrowser = "librewolf";
  myTerminal = "kitty";
  myShell = "fish";
  myEditor = "nvim";
  myFileManager = "yazi";
  myUserName = "krit";
  isCatppuccin = true;

  # 🌟 APP WORKSPACES (Keep 1 and 6 free. Keyboard key 0 = 10)
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    other = "5";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
  };

  # Add more if needed
  termApps = [
    "nvim"
    "neovim"
    "vim"
    "nano"
    "hx"
    "helix"
    "yazi"
    "ranger"
    "lf"
    "nnn"
  ];
  smartLaunch =
    app: if builtins.elem app termApps then "${myTerminal} --class ${app} -e ${app}" else app;

  # 🌟 DESKTOP MAP & RESOLVE FUNCTION
  desktopMap = {
    "firefox" = "firefox.desktop";
    "librewolf" = "librewolf.desktop";
    "google-chrome" = "google-chrome.desktop";
    "chromium" = "chromium-browser.desktop";
    "brave" = "brave-browser.desktop";
    "nvim" = "custom-nvim.desktop";
    "code" = "code.desktop";
    "kate" = "org.kde.kate.desktop";
    "yazi" = "yazi.desktop";
    "ranger" = "ranger.desktop";
    "dolphin" = "org.kde.dolphin.desktop";
    "thunar" = "thunar.desktop";
    "Nautilus" = "org.gnome.Nautilus.desktop";
    "nemo" = "nemo.desktop";
  };
  resolve = name: desktopMap.${name} or "${name}.desktop";
in

delib.host {
  name = "nixos-desktop";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-desktop";
        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "krit";
        gitUserName = "nicolkrit999";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = myTerminal;
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;
        # ---------------------------------------------------------------
        # ⚙️ ADVANCED SYSTEM CONSTANTS
        # ---------------------------------------------------------------

        # ---------------------------------------------------------------
        # 🖼️ MONITORS & WALLPAPERS
        # ---------------------------------------------------------------
        monitors = [
          "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
          "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"
          "DP-3, disable"
          "HDMI-A-1,1920x1080@60, 0x0, 1, mirror, DP-1"
        ];

        wallpapers = [
          {
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/JoydeepMallick/Wallpapers/Anime-Girl2.png";
            wallpaperSHA256 = "05ad0c4lm47rh67hsymz0si7x62b7sanz91dsf2vaz68973fq6k6";
          }

          {
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/zhichaoh-catppuccin-wallpapers-main/os/nix-black-4k.png";
            wallpaperSHA256 = "144mz3nf6mwq7pmbmd3s9xq7rx2sildngpxxj5vhwz76l1w5h5hx";
          }
        ];

        # ---------------------------------------------------------------
        # 🎨 THEMING
        # ---------------------------------------------------------------
        theme = {
          polarity = "dark";
          base16Theme = "catppuccin-mocha";
          catppuccin = true;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "teal";
        };

        screenshots = "$HOME/Pictures/Screenshots";
        keyboardLayout = "us,it,de,fr";
        keyboardVariant = "intl,,,";

        # 🌟 RESTORED FROM VARIABLES.NIX.BAK
        weather = "Lugano";
        useFahrenheit = false;
        nixImpure = false;

        timeZone = "Etc/UTC";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth.enable = true;

      cachix = {
        enable = true;
        push = true; # Only the builder must have this true (for now "nixos-desktop")
      };

      cosmic.enable = true; # TODO: Change name to programs.cosmic to allow a single switch (do a nix flake check and a dry build before confiirming this change)
      gnome.enable = true; # TODO: Change name to programs.cosmic to allow a single switch (do a nix flake check and a dry build before confiirming this change)
      guest.enable = true;
      home-packages.enable = true;
      hyprland.enable = true; # TODO: Change name to programs.cosmic to allow a single switch (do a nix flake check and a dry build before confiirming this change)
      kde.enable = true; # TODO: Change name to programs.cosmic to allow a single switch (do a nix flake check and a dry build before confiirming this change)
      mime.enable = true;
      nh.enable = true;
      niri.enable = true; # TODO: Change name to programs.cosmic to allow a single switch (do a nix flake check and a dry build before confiirming this change)
      qt.enable = true;

      zram = {
        enable = true;
        zramPercent = 25;
      };

      stylix = {
        enable = true;
        targets = {
          yazi.enable = false;
          cava.enable = true;
          kitty.enable = !isCatppuccin;
          alacritty.enable = !isCatppuccin;
          zathura.enable = !isCatppuccin;
          firefox.profileNames = [ myUserName ];
          librewolf.profileNames = [
            "default"
            "privacy"
          ];
        };
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs.bat.enable = true;
      programs.cosmic.enable = true;
      programs.eza.enable = true;
      programs.fzf.enable = true;

      programs.git = {
        enable = true;
        customGitIgnores = [ ];
      };

      programs.lazygit.enable = true;
      programs.shell-aliases.enable = true;
      programs.starship.enable = true;
      programs.tmux.enable = true;
      programs.walker.enable = true;

      programs.waybar = {
        enable = true;

        waybarLayout = {
          "format-en" = "🇺🇸-EN";
          "format-it" = "🇮🇹-IT";
          "format-de" = "🇩🇪-DE";
          "format-fr" = "🇫🇷-FR";
        };

        waybarWorkspaceIcons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          "6" = "";
          "7" = ":";
          "8" = ":";
          "9" = ":";
          "10" = ":";
          "magic" = ":";
        };
      };

      programs.zoxide.enable = true;

      programs.caelestia = {
        enable = true;
        enableOnHyprland = false;
      };

      programs.noctalia = {
        enable = true;
        enableOnHyprland = false;
        enableOnNiri = true;
      };

      programs.hyprland = {
        enable = true;
        execOnce = [
          "${myBrowser}"
          "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
          "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
          "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"

          "sleep 4 && uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
          "whatsapp-electron"
        ];
        monitorWorkspaces = [
          "1, monitor:DP-1"
          "2, monitor:DP-1"
          "3, monitor:DP-1"
          "4, monitor:DP-1"
          "5, monitor:DP-1"
          "6, monitor:DP-2"
          "7, monitor:DP-2"
          "8, monitor:DP-2"
          "9, monitor:DP-2"
          "10, monitor:DP-2"
        ];

        windowRules = [

          # 1. Smart Launcher Rules
          "workspace ${appWorkspaces.editor}, class:^(${myEditor})$"
          "workspace ${appWorkspaces.fileManager}, class:^(${myFileManager})$"
          "workspace ${appWorkspaces.terminal}, class:^(${myTerminal})$"

          "workspace ${appWorkspaces.editor} silent, class:^(code)$"
          "workspace ${appWorkspaces.editor} silent, class:^(nvim-editor)$"
          "workspace ${appWorkspaces.editor} silent, class:^(org.kde.kate)$"
          "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-pycharm-ce)$"
          "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-Clion)$"
          "workspace ${appWorkspaces.editor} silent, class:^(jetbrains-idea-ce)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(org.kde.dolphin)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(thunar)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(yazi)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(ranger)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(org.gnome.Nautilus)$"
          "workspace ${appWorkspaces.fileManager} silent, class:^(nemo)$"
          "workspace ${appWorkspaces.vm} silent, class:^(winboat)$"
          "workspace ${appWorkspaces.other} silent, class:^(Actual)$"
          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(chromium-browser)$"
          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-browser)$"
          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(brave-.*\..*)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(kitty)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(alacritty)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(foot)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(xfce4-terminal)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(com.system76.CosmicTerm)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(org.kde.konsole)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(gnome-terminal)$"
          "workspace ${appWorkspaces.terminal} silent, class:^(XTerm)$"
          "workspace ${appWorkspaces.chat} silent, class:^(vesktop)$"
          "workspace ${appWorkspaces.chat} silent, class:^(org.telegram.desktop)$"
          "workspace ${appWorkspaces.chat} silent, class:^(whatsapp-electron)$"

          # Scratchpad rules
          "float, class:^(scratch-term)$"
          "center, class:^(scratch-term)$"
          "size 80% 80%, class:^(scratch-term)$"
          "workspace special:magic, class:^(scratch-term)$"
          "float, class:^(scratch-fs)$"
          "center, class:^(scratch-fs)$"
          "size 80% 80%, class:^(scratch-fs)$"
          "workspace special:magic, class:^(scratch-fs)$"
          "float, class:^(scratch-browser)$"
          "center, class:^(scratch-browser)$"
          "size 80% 80%, class:^(scratch-browser)$"
          "workspace special:magic, class:^(scratch-browser)$"

          # Winboat rules
          "workspace ${appWorkspaces.vm}, class:^winboat-.*$"
          "suppressevent fullscreen maximize activate activatefocus, class:^winboat-.*$"
          "noinitialfocus, class:^winboat-.*$"
          "noanim, class:^winboat-.*$"
          "norounding, class:^winboat-.*$"
          "noshadow, class:^winboat-.*$"
          "noblur, class:^winboat-.*$"
          "opaque, class:^winboat-.*$"
        ];

        extraBinds = [
          "$Mod SHIFT, return, exec, [workspace special:magic] $term --class scratch-term"
          "$Mod SHIFT, F, exec, [workspace special:magic] $term --class scratch-fs -e yazi"
          "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
          "$Mod,       Y, exec, chromium-browser"
        ];
      };

      programs.niri = {
        enable = true;
        execOnce = [
          "${myBrowser}"
          "${myEditor}"
          "${myFileManager}"
          "${myTerminal}"
          "chromium-browser"
        ];
      };

      programs.gnome = {
        enable = true;
        screenshots = "/home/krit/Pictures/Screenshots";
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
          "github-desktop.desktop"
          "LocalSend.desktop"
          "proton-pass.desktop"
          "vesktop.desktop"
          "com.github.dagmoller.whatsapp-electron.desktop"
          "com.actualbudget.actual.desktop"
        ];
        extraBinds = [
          {
            name = "Launch Chromium";
            command = "chromium";
            binding = "<Super>y";
          }
        ];
      };

      programs.kde = {
        enable = true;
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
          "github-desktop.desktop"
          "LocalSend.desktop"
          "proton-pass.desktop"
          "vesktop.desktop"
          "com.github.dagmoller.whatsapp-electron.desktop"
          "com.actualbudget.actual.desktop"
        ];
        extraBinds = {
          "launch-chromium" = {
            key = "Meta+Y";
            command = "chromium";
          };
        };

      };

      # ---------------------------------------------------------------
      # ⚙️ SERVICES
      # ---------------------------------------------------------------
      services.audio.enable = true;
      services.hyprlock.enable = true;
      services.sddm.enable = true;

      services.snapshots = {
        enable = true;
        retention = {
          hourly = "24";
          daily = "7";
          weekly = "4";
          monthly = "3";
          yearly = "2";
        };
      };

      services.tailscale.enable = true;

      services.hypridle = {
        enable = true;
        dimTimeout = 900;
        lockTimeout = 1800;
        screenOffTimeout = 3600;
      };

      services.swaync = {
        enable = true;
        customSettings = {
          "mute-protonvpn" = {
            state = "ignored";
            app-name = ".*Proton.*";
          };
        };
      };

      # ---------------------------------------------------------------
      # 👤 KRIT PROGRAMS
      # ---------------------------------------------------------------
      krit.programs.alacritty.enable = true;
      krit.programs.kitty.enable = true;
      krit.programs.cava.enable = true;
      krit.programs.chromium.enable = true;
      krit.programs.direnv.enable = true;
      krit.programs.dolphin.enable = true;
      krit.programs.firefox.enable = true;
      krit.programs.librewolf.enable = true;
      krit.programs.neovim.enable = true;
      krit.programs.pwas.enable = true;
      krit.programs.ranger.enable = true;
      krit.programs.yazi.enable = true;
      krit.programs.zathura.enable = true;

      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.desktop.flatpak.enable = true;
      krit.services.desktop.local-packages.enable = true;

      krit.services.logitech = {
        enable = true;
        mouses.mx-master.enable = true;
        mouses.superlight.enable = true;
      };

      krit.services.nas = {
        desktop-borg-backup.enable = true;
        owncloud.enable = true;
        smb.enable = true;
        sshfs.enable = true;
      };

    };

  # ---------------------------------------------------------------
  # ⚙️ SYSTEM-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  nixos =
    { ... }:
    {
      system.stateVersion = "25.11";
      imports = [
        inputs.catppuccin.nixosModules.catppuccin
        inputs.nix-sops.nixosModules.sops
        inputs.niri.nixosModules.niri

        ./hardware-configuration.nix

        (
          { config, ... }:
          {
            sops.templates."davfs-secrets" = {
              content = ''
                ${config.sops.placeholder.nas_owncloud_url} ${config.sops.placeholder.nas_owncloud_user} ${config.sops.placeholder.nas_owncloud_pass}
              '';
              owner = "root";
              group = "root";
              mode = "0600";
            };

            # 🚀 INJECT SECRETS INTO MODULES
            myconfig.krit.services.nas.sshfs.identityFile = config.sops.secrets.nas_ssh_key.path;
            myconfig.krit.services.nas.smb.credentialsFile = config.sops.secrets.nas-krit-credentials.path;
            myconfig.krit.services.nas.desktop-borg-backup.passphraseFile =
              config.sops.secrets.borg-passphrase.path;
            myconfig.krit.services.nas.desktop-borg-backup.sshKeyPath =
              config.sops.secrets.borg-private-key.path;
            myconfig.krit.services.nas.owncloud.secretsFile = config.sops.templates."davfs-secrets".path;

            # Other config-dependent settings
            nix.extraOptions = ''
              !include ${config.sops.secrets.github_fg_pat_token_nix.path}
            '';

            programs.ssh.extraConfig = ''
              Host github.com
              IdentityFile ${config.sops.secrets.github_general_ssh_key.path}
            '';

            users.users.${myUserName}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
          }
        )
      ];

      i18n.defaultLocale = "en_US.UTF-8";

      sops.defaultSopsFile = ./nixos-desktop-secrets-sops.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      # ---------------------------------------------------------
      # 🔐 CENTRALIZED SOPS DEFINITIONS
      # ---------------------------------------------------------
      sops.secrets =
        let
          commonSecrets = ../../users/krit/sops/krit-common-secrets-sops.yaml;
        in
        {
          "krit-local-password".neededForUsers = true;

          github_fg_pat_token_nix = {
            sopsFile = commonSecrets;
            mode = "0444";
          };
          github_general_ssh_key = {
            sopsFile = commonSecrets;
            owner = myUserName;
            path = "/home/${myUserName}/.ssh/id_github";
          };
          Krit_Wifi_pass = {
            sopsFile = commonSecrets;
            restartUnits = [ "NetworkManager.service" ];
          };
          Nicol_5Ghz_pass = {
            sopsFile = commonSecrets;
            restartUnits = [ "NetworkManager.service" ];
          };
          Nicol_2Ghz_pass = {
            sopsFile = commonSecrets;
            restartUnits = [ "NetworkManager.service" ];
          };
          commit_signing_key = {
            sopsFile = commonSecrets;
            owner = myUserName;
          };

          nas_ssh_key.sopsFile = commonSecrets;
          nas-krit-credentials.sopsFile = commonSecrets;
          nas_owncloud_url.sopsFile = commonSecrets;
          nas_owncloud_user.sopsFile = commonSecrets;
          nas_owncloud_pass.sopsFile = commonSecrets;

          borg-passphrase = { };
          borg-private-key = { };
          cachix-auth-token = { };
        };

      programs.git.enable = true;
      programs.git.config = {
        user.signingkey = "D93A24D8E063EECF";
        commit.gpgsign = true;
      };

      programs.gnupg.agent = {
        enable = true;
        enableSSHSupport = true;
        pinentryPackage = pkgs.pinentry-qt;
      };

      boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # Allow emulation of aarch64-linux. For example allow nix-flake-check for the arm laptop
      boot.initrd.kernelModules = [ "amdgpu" ];
      hardware.graphics.enable = true;

      services.logind.settings.Login = {
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
      };

      users.mutableUsers = false;
      users.users.${myUserName} = {
        isNormalUser = true;
        description = "${myUserName}";
        extraGroups = [
          "wheel"
          "networkmanager"
          "input"
          "docker"
          "podman"
          "video"
          "audio"
        ];
        subUidRanges = [
          {
            startUid = 100000;
            count = 65536;
          }
        ];
        subGidRanges = [
          {
            startGid = 100000;
            count = 65536;
          }
        ];
      };

      virtualisation.docker.enable = true;
      virtualisation.docker.daemon.settings."mtu" = 1450;
      virtualisation.podman = {
        enable = true;
        dockerCompat = false;
      };

      services.resolved = {
        enable = true;
        dnssec = "false";
        domains = [ "~." ];
        fallbackDns = [
          "9.9.9.9"
          "149.112.112.112"
        ];
        dnsovertls = "opportunistic";
      };

      systemd.services.cleanup_trash = {
        description = "Clean up trash older than 30 days";
        serviceConfig = {
          Type = "oneshot";
          User = myUserName;
          Environment = "HOME=/home/${myUserName}";
          ExecStart = "${pkgs.autotrash}/bin/autotrash -d 30";
        };
      };

      systemd.timers.cleanup_trash = {
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      # Solve Home-manager portal assertion
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      environment.systemPackages = with pkgs; [
        autotrash
        docker
        distrobox
        fd
        gnupg
        pinentry-qt
        pinentry-curses
        libvdpau-va-gl
        pay-respects
        pokemon-colorscripts
        stow
        tree
        unzip
        wget
        zip
        zlib
      ];
    };

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  home =
    { ...
    }:
    {
      home.stateVersion = "25.11";
      imports = [

        inputs.nix-sops.homeModules.sops

      ];


      home.packages = (with pkgs; [ winboat ]) ++ (with pkgs-unstable; [ ]);

      xdg.userDirs = {
        publicShare = null;
        music = null;
      };

      home.activation = {
        # Input home manager here to bypass "function home" and "attributes hm missing" evaluation errors
        createHostDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/Pictures/wallpapers
          mkdir -p $HOME/momentary
        '';
      };
    };
}
