{
  delib,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # 🌟 CORE APPS & THEME
  myBrowser = "librewolf";
  myTerminal = "kitty";
  myEditor = "nvim";
  myFileManager = "yazi";
  isCatppuccin = true;
  userName = "krit";

  # For a laptop it would make sense to change them but i keep them the same as desktop for muscle memory
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    other = "5";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
  };

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

  # ---------------------------------------------------------------------------
  # 🖥️ WM / DE SPECIFIC CONFIGURATIONS (Migrated from modules.nix)
  # ---------------------------------------------------------------------------

  myHyprlandWindowRules = [
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

  myHyprlandExtraBinds = [
    "$Mod SHIFT, return, exec, [workspace special:magic] $term --class scratch-term"
    "$Mod SHIFT, F, exec, [workspace special:magic] $term --class scratch-fs -e yazi"
    "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
    "$Mod,       Y, exec, chromium-browser"
  ];

  myGnomeExtraBinds = [
    {
      name = "Launch Chromium";
      command = "chromium";
      binding = "<Super>y";
    }
  ];

  myKdeExtraBinds = {
    "launch-chromium" = {
      key = "Meta+Y";
      command = "chromium";
    };
  };

  myWaybarWorkspaceIcons = {
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

  myWaybarLayout = {
    "format-en" = "🇺🇸-EN";
    "format-it" = "🇮🇹-IT";
    "format-de" = "🇩🇪-DE";
    "format-fr" = "🇫🇷-FR";
  };
in
delib.host {
  name = "nixos-laptop";
  type = "laptop";

  homeManagerSystem = "aarch64-linux";

  myconfig =
    { name, ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-laptop";
        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "krit";
        gitUserName = "nicolkrit999";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = "kitty";
        shell = "fish";
        browser = "librewolf";
        editor = "nvim";
        fileManager = "yazi";
        # ---------------------------------------------------------------
        # ⚙️ ADVANCED SYSTEM CONSTANTS
        # ---------------------------------------------------------------

        # ---------------------------------------------------------------
        # 🖼️ MONITORS & WALLPAPERS
        # ---------------------------------------------------------------
        monitors = [
          # 💻 Built-in Laptop Screen (Adjust resolution/scale as needed)
          "eDP-1,2880x1800@120,0x0,1"

          # 🖥️ Your Desktop Monitors (Ignored until plugged in)
          "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
          "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"

          # 🔌 Catch-all fallback for any other random screen you plug in
          # FIXME: This is a good thing but to enable it the wallpaper applying logic must be changed to allow this kind of sintax
          #",preferred,auto,1"
        ];

        # Keep all 3 wallpaper to work when connected to external monitors (built in monitor is disabled and so the external monitors still ahve the right one)
        wallpapers = [

          {
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/JoydeepMallick/Wallpapers/Anime-Girl2.png";
            wallpaperSHA256 = "05ad0c4lm47rh67hsymz0si7x62b7sanz91dsf2vaz68973fq6k6";
          }

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
        push = false; # Only the builder must have this true (for now "nixos-desktop")
      };

      cosmic.enable = true;
      gnome.enable = true;
      guest.enable = true;
      home-packages.enable = true;
      hyprland.enable = true;
      kde.enable = true;
      mime.enable = true;
      nh.enable = true;
      niri.enable = true;
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
          firefox.profileNames = [ userName ];
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
      programs.starship.enable = true;
      programs.tmux.enable = true;
      programs.walker.enable = true;

      programs.waybar = {
        enable = true;
        waybarLayout = myWaybarLayout;
        waybarWorkspaceIcons = myWaybarWorkspaceIcons;
      };

      programs.zoxide.enable = true;

      programs.caelestia = {
        enable = false;
        enableOnHyprland = false;
      };

      programs.noctalia = {
        enable = false;
        enableOnHyprland = false;
        enableOnNiri = false;
      };

      programs.hyprland = {
        enable = true;
        execOnce = [
        ];
        windowRules = myHyprlandWindowRules;
        extraBinds = myHyprlandExtraBinds;
      };

      programs.niri = {
        enable = true;
        execOnce = [
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
        gnomeExtraBinds = myGnomeExtraBinds;
      };

      programs.kde = {
        enable = true;
        extraBinds = myKdeExtraBinds;
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
          hourly = "6";
          daily = "3";
          weekly = "2";
          monthly = "1";
          yearly = "0";
        };
      };

      services.tailscale.enable = true;

      services.hypridle = {
        enable = true;
        dimTimeout = 180;
        lockTimeout = 300;
        screenOffTimeout = 360;
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
      krit.programs.alacritty.enable = false;
      krit.programs.cava.enable = true;
      krit.programs.chromium.enable = false;
      krit.programs.direnv.enable = true;
      krit.programs.dolphin.enable = true;
      krit.programs.firefox.enable = false;
      krit.programs.librewolf.enable = true;
      krit.programs.neovim.enable = true;
      krit.programs.pwas.enable = true;
      krit.programs.ranger.enable = false;
      krit.programs.yazi.enable = true;
      krit.programs.zathura.enable = true;

      # ---------------------------------------------------------------
      # 👤 KRIT SERVICES
      # ---------------------------------------------------------------
      krit.services.laptop.flatpak.enable = true;
      krit.services.laptop.local-packages.enable = true;

      krit.services.logitech = {
        enable = true;
        mouses.mx-master.enable = true;
        mouses.superlight.enable = false;
      };

      # TODO: Enable when host sops secrets are configured
      # They can all be enabled since they are active only on request
      /*
        krit.services.nas = {
          laptop-borg-backup.enable = true;
          owncloud.enable = true;
          smb.enable = true;
          sshfs.enable = true;
        };
      */

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
        #inputs.nix-sops.nixosModules.sops # TODO: Enable when host sops secrets are configured
        inputs.niri.nixosModules.niri

        ./hardware-configuration.nix

        # 🌟 THE INLINE MODULE FIX 🌟
        # Anything that uses the word 'config' MUST be inside here!
        /*
          (
            { config, ... }:
            # TODO: Enable when host sops secrets are configured

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
              myconfig.krit.services.nas.laptop-borg-backup.passphraseFile =
                config.sops.secrets.borg-passphrase.path;
              myconfig.krit.services.nas.laptop-borg-backup.sshKeyPath =
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

              users.users.${userName}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
            }

          )
        */
      ];

      i18n.defaultLocale = "en_US.UTF-8";

      # TODO: Enable when host sops secrets are configured
      /*
        sops.defaultSopsFile = ./nixos-laptop-secrets-sops.yaml;
        sops.defaultSopsFormat = "yaml";
        sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      */

      # ---------------------------------------------------------
      # 🔐 CENTRALIZED SOPS DEFINITIONS
      # ---------------------------------------------------------
      /*
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
              owner = userName;
              path = "/home/${userName}/.ssh/id_github";
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
              owner = userName;
            };

            nas_ssh_key.sopsFile = commonSecrets;
            nas-krit-credentials.sopsFile = commonSecrets;
            nas_owncloud_url.sopsFile = commonSecrets;
            nas_owncloud_user.sopsFile = commonSecrets;
            nas_owncloud_pass.sopsFile = commonSecrets;

            # 🌟 THE FIX: Remove the commonSecrets override so they use defaultSopsFile
            borg-passphrase = { };
            borg-private-key = { };
            cachix-auth-token = { }; # Added this so Cachix can push!
          };
      */

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

      # TODO: configure with the intel one
      #boot.initrd.kernelModules = [ "" ];
      #hardware.graphics.enable = true;

      # TODO: see without it if the button already does a
      services.logind.settings.Login = {
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
      };

      #users.mutableUsers = false;
      users.users.${userName} = {
        isNormalUser = true;
        description = "${userName}";
        extraGroups = [
          "networkmanager"
          "wheel"
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

      virtualisation.docker.enable = false;
      virtualisation.docker.daemon.settings."mtu" = 1450;
      virtualisation.podman = {
        enable = false;
        dockerCompat = false;
      };

      # TODO: check stability. Ideally keep enabled. If it cause problems on public wifi remove it
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
        description = "Clean up trash older than 5 days";
        serviceConfig = {
          Type = "oneshot";
          User = userName;
          Environment = "HOME=/home/${userName}";
          ExecStart = "${pkgs.autotrash}/bin/autotrash -d 5";
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

      # ---------------------------------------------------------
      # ⚡ POWER MANAGEMENT twaks
      # ---------------------------------------------------------
      services.speechd.enable = lib.mkForce false; # Disable speech-dispatcher as it is not needed and wastes resources
      systemd.services.ModemManager.enable = false; # Disable unused 4G modem scanning

      networking.networkmanager.wifi.powersave = true; # Micro-sleeps radio between packets
      powerManagement.powertop.enable = true; # Sleeps idle USB, Audio, and PCI devices

      boot.kernelParams = [
        # "pcie_aspm=force" # Force deep sleep for SSD & Motherboard (this may cause instability, include it without it first and test)
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
    }; # 🌟 THIS CORRECTLY CLOSES THE NIXOS BLOCK

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  home =
    {
      ...
    }:
    {
      home.stateVersion = "25.11";
      imports = [

        # TODO: Enable when host sops secrets are configured
        #inputs.nix-sops.homeModules.sops

      ];

      # TODO: check stability. It should not be necessary since vivaldi was removed
      /*
        xdg.desktopEntries.vivaldi = {
          name = "Vivaldi";
          genericName = "Web Browser";
          exec = "/home/${userName}/.local/bin/vivaldi %U";
          terminal = false;
          categories = [
            "Network"
            "WebBrowser"
          ];
          mimeType = [
            "text/html"
            "application/xhtml+xml"
            "x-scheme-handler/http"
            "x-scheme-handler/https"
          ];
          icon = "vivaldi";
        };

        home.file.".local/bin/vivaldi" = {
          executable = true;
          text = ''
            #!/bin/sh
            exec env QT_QPA_PLATFORMTHEME=gtk3 ${pkgs.vivaldi}/bin/vivaldi --password-store=gnome-libsecret "$@"
          '';
        };
      */

      home.packages = (with pkgs; [ ]) ++ (with pkgs-unstable; [ ]);

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
