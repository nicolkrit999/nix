{ delib
, ...
}:
let
  # 🌟 CORE APPS & THEME
  myBrowser = "librewolf";
  myTerminal = "kitty";
  myShell = "fish";
  myEditor = "nvim";
  myFileManager = "yazi";
  myUserName = "krit";
  myLocale = "en_US.UTF-8";
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
  name = "nixos-arm-vm";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "nixos-arm-vm";
        mainLocale = myLocale;

        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = "krit";
        gitUserName = "Krit Pio Nicol";
        gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = myTerminal;
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        wallpapers = [
          {
            targetMonitor = "DP-1";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/AngelJumbo/gruvbox-wallpapers/gruvbox-wallpapers-main/wallpapers/anime/Kurumi-Ebisuzawa.png";
            wallpaperSHA256 = "1rn290hx0vl70w1dvksqrp8n713zyswc0gm98zsh962nw9jrkmrk";
          }

          {
            targetMonitor = "*";
            wallpaperURL = "https://raw.githubusercontent.com/nicolkrit999/wallpapers-repo/main/wallpapers/Pictures/wallpapers/various/other-user-github-repos/AngelJumbo/gruvbox-wallpapers/gruvbox-wallpapers-main/wallpapers/brands/gruvbox-nix.png";
            wallpaperSHA256 = "18j302fdjfixi57qx8vgbg784ambfv9ir23mh11rqw46i43cdqjs";
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

        weather = "Lugano";
        useFahrenheit = false;
        nixImpure = false;


        timeZone = "Europe/Zurich";
      };

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth.enable = true;

      cachix = {
        enable = true;
        push = true; # Only the builder must have this true (for now "nixos-arm-vm")
      };

      guest.enable = true;
      home-packages.enable = true;
      mime.enable = true;
      nh.enable = true;
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
        enableOnNiri = false;
      };

      programs.hyprland = {
        enable = true;
        monitors = [
          "DP-1,3840x2160@240,1440x560,1.5,bitdepth,10"
          "DP-2,3840x2160@144,0x0,1.5,transform,1,bitdepth,10"
          "DP-3, disable"
          "HDMI-A-1,1920x1080@60, 0x0, 1, mirror, DP-1"
        ];
        execOnce = [
          "${myBrowser}"
          "[workspace ${appWorkspaces.editor} silent] ${smartLaunch myEditor}"
          "[workspace ${appWorkspaces.fileManager} silent] ${smartLaunch myFileManager}"
          "[workspace ${appWorkspaces.terminal} silent] ${myTerminal}"

          "uwsm app -- brave --app=https://www.youtube.com --password-store=gnome"
          "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'"
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
          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(org.jellyfin.JellyfinDesktop)$"
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
          "workspace ${appWorkspaces.chat} silent, class:^(com.rtosta.zapzap)$"

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
          "$Mod SHIFT, return, exec, [workspace special:magic] ${myTerminal} --class scratch-term"
          "$Mod SHIFT, F, exec, [workspace special:magic] ${myTerminal} --class scratch-fs -e yazi"
          "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
          "$Mod,       Y, exec, chromium-browser"
        ];
      };

      programs.niri = {
        enable = true;
        outputs = {
          "DP-1" = {
            mode = {
              width = 3840;
              height = 2160;
              refresh = 240.0;
            };
            scale = 1.5;
            position = {
              x = 1440;
              y = 560;
            };
          };
          "DP-2" = {
            mode = {
              width = 3840;
              height = 2160;
              refresh = 144.0;
            };
            scale = 1.5;
            position = {
              x = 0;
              y = 0;
            };
            transform = {
              rotation = 90;
              flipped = false;
            };
          };
          "DP-3" = {
            enable = false;
          };
          "HDMI-A-1" = {
            mode = {
              width = 1920;
              height = 1080;
              refresh = 60.0;
            };
            scale = 1.0;
          };
        };
        execOnce = [
          "${myBrowser}"
          "${myEditor}"
          "${myFileManager}"
          "${myTerminal}"
          "chromium-browser"
          "sh -c 'sleep 3 && flatpak run com.rtosta.zapzap'" # Sleep necessary to allow loading right polarity
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
          "com.actualbudget.actual.desktop"
          "com.rtosta.zapzap.desktop"
        ];
        extraBinds = [
          {
            name = "Launch Chromium";
            command = "chromium";
            binding = "<Super>y";
          }
        ];
      };

      programs.cosmic = {
        enable = true;
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
          "com.actualbudget.actual.desktop"
          "com.actualbudget.actual.desktop"
          "com.rtosta.zapzap.desktop" # Sleep necessary to allow loading right polarity
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
      services.impermanence.enable = true;

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
      krit.services.arm-vm.flatpak.enable = true;
      krit.services.arm-vm.local-packages.enable = true;

      krit.services.logitech = {
        enable = true;
        mouses.mx-master-3s.enable = true;
        mouses.mx-master-4.enable = true;
        mouses.superlight.enable = true;
      };


      krit.services.nas = {
        desktop-borg-backup.enable = true;
        owncloud.enable = true;
        smb.enable = true;
        sshfs.enable = true;
      };

    };
}

