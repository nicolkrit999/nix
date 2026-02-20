{ delib, ... }:
let
  # 🌟 CORE APPS & THEME
  myBrowser = "librewolf";
  myTerminal = "kitty";
  myEditor = "nvim";
  myFileManager = "yazi";
  isCatppuccin = true;
  userName = "krit";

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

  myHyprlandWorkspaces = [
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

  # Commented because 2 logitech mice connected, but preserved for logic
  /*
    kdeMice = [
      { enable = true; name = "Logitech G403"; vendorId = "046d"; productId = "c08f"; acceleration = -1.0; accelerationProfile = "none"; }
    ];
  */

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
  name = "nixos-desktop";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { name, ... }:
    {
      constants = {
        user = "krit";
        browser = myBrowser;
        terminal = myTerminal;
        editor = myEditor;
        fileManager = myFileManager;
        gitUserName = "nicolkrit999";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";
        shell = "fish";

        keyboardLayout = "us,it,de,fr";
        keyboardVariant = "intl,,,";
        weather = "Lugano";
        useFahrenheit = false;
        nixImpure = false;
        customGitIgnores = [ ];

        zramPercent = 25;

        snapshots = true;
        snapshotRetention = {
          hourly = "24";
          daily = "7";
          weekly = "4";
          monthly = "3";
          yearly = "2";
        };

        cachix = {
          enable = true;
          push = true; # Only the builder must have this true (for now "nixos-desktop")
          name = "krit-nixos";
          publicKey = "krit-nixos.cachix.org-1:54bU6/gPbvP4X+nu2apEx343noMoo3Jln8LzYfKD7ks=";
        };

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
        ];

        theme = {
          polarity = "dark";
          base16Theme = "catppuccin-mocha";
          catppuccin = true;
          catppuccinFlavor = "mocha";
          catppuccinAccent = "teal";
        };

      };

      # 🎛️ MODULE TOGGLES & INJECTIONS
      programs.hyprland = {
        enable = true;
        execOnce = [
          "uwsm app -- $term"
          "sleep 2 && uwsm app -- $browser"
          "uwsm app -- $editor"
          "uwsm app -- $fileManager"
          "sleep 4 && uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
          "whatsapp-electron"
        ];
        # Appending the strict lists mapped in the `let` block
        monitorWorkspaces = myHyprlandWorkspaces;
        windowRules = myHyprlandWindowRules;
        extraBinds = myHyprlandExtraBinds;
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
        gnomeExtraBinds = myGnomeExtraBinds;
      };

      programs.kde = {
        enable = true;
        extraBinds = myKdeExtraBinds;
        # mice = kdeMice;
      };

      programs.cosmic.enable = true;

      programs.waybar = {
        enable = true;
        workspaceIcons = myWaybarWorkspaceIcons;
        layout = myWaybarLayout;
      };

      programs.stylix = {
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

      programs.swaync = {
        enable = true;
        customSettings = {
          "mute-protonvpn" = {
            state = "ignored";
            app-name = ".*Proton.*";
          };
        };
      };

      services.hypridle = {
        enable = true;
        dimTimeout = 300;
        lockTimeout = 330;
        screenOffTimeout = 360;
      };
      programs.hyprlock.enable = true;

      krit.guest.enable = true;
      services.tailscale.enable = true;
      services.bluetooth.enable = true;
      services.samba.enable = true;
      services.flatpak.enable = true;

      # -----------------------------------------------
      # 🪟 CUSTOM SHELLS
      # -----------------------------------------------
      programs.caelestia.enableOnHyprland = false;

      programs.noctalia = {
        enableOnHyprland = false;
        enableOnNiri = false;
      };

      # ... keep the rest ...
      krit.hardware.logitech.enable = true;

      timeZone = "Europe/Zurich";
    };

  # ---------------------------------------------------------------
  # ⚙️ SYSTEM-LEVEL CONFIGURATIONS
  # ---------------------------------------------------------------
  nixos =
    {
      config,
      pkgs,
      lib,
      ...
    }:
    {
      system.stateVersion = "25.11";
      imports = [
        ./hardware-configuration.nix
        ./optional/default.nix
      ];

      i18n.defaultLocale = "en_US.UTF-8";

      sops.defaultSopsFile = ./optional/host-sops-nix/nixos-desktop-secrets-sops.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

      sops.secrets =
        let
          commonSecrets = ../../../krit/sops/krit-common-secrets-sops.yaml;
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
        };

      nix.extraOptions = ''
        !include ${config.sops.secrets.github_fg_pat_token_nix.path}
      '';

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

      programs.ssh = {
        extraConfig = ''
          Host github.com
          IdentityFile ${config.sops.secrets.github_general_ssh_key.path}
        '';
      };

      boot.initrd.kernelModules = [ "amdgpu" ];
      hardware.graphics.enable = true;

      services.logind.settings.Login = {
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
      };

      users.mutableUsers = false;
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
        hashedPasswordFile = config.sops.secrets.krit-local-password.path;
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
          User = userName;
          Environment = "HOME=/home/${userName}";
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
    {
      pkgs,
      pkgs-unstable,
      config,
      lib,
      ...
    }:
    {
      home.stateVersion = "25.11";
      imports = [
        ./optional/host-hm-modules
      ];

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

      home.packages = (with pkgs; [ winboat ]) ++ (with pkgs-unstable; [ ]);

      xdg.userDirs = {
        publicShare = null;
        music = null;
      };

      home.activation = {
        createHostDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p $HOME/Pictures/wallpapers
          mkdir -p $HOME/momentary
        '';
      };
    };
}
