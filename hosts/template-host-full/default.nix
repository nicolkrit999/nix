# TEMPLATE-HOST FULL CONFIGURATION
# THIS IS A TEMPLATE THAT SHOW A CONFIGURATION OF EVERY POSSIBLE FEATURE THE CURRENT SETUP ALLOW
{ delib
, inputs
, pkgs
, ...
}:
let
  pkgs-unstable = inputs.nixpkgs-unstable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  # 🌟 CORE APPS & THEME
  # Choose core preferences
  myBrowser = "firefox";
  myTerminal = "alacritty";
  myShell = "bash";
  myEditor = "nvim";
  myFileManager = "dolphin";
  myUserName = "krit";
  isCatppuccin = true; # Choose if enabling the  official catppuccin-nix module or not

  # 🌟 APP WORKSPACES (Keep 1 and 6 free. Keyboard key 0 = 10)
  # Choose if binding a certain application to a specific workspace. Currently only in hyprland
  appWorkspaces = {
    editor = "2";
    fileManager = "3";
    vm = "4";
    other = "5";
    browser-Entertainment = "7";
    terminal = "8";
    chat = "9";
  };

  # This is used to distinguish between terminal-based and gui applications to make keybindings smart
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

  # # This is used to distinguish between terminal-based and gui applications to make desktop name smart
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
  name = "template-host";
  type = "desktop";

  homeManagerSystem = "x86_64-linux";

  myconfig =
    { ... }:
    {
      # ---------------------------------------------------------------
      # 📦 CONSTANTS BLOCK (Data Bucket)
      # ---------------------------------------------------------------
      constants = {
        hostname = "template-host";
        # ---------------------------------------------------------------
        # 👤 USER IDENTITY
        # ---------------------------------------------------------------
        user = myUserName;
        gitUserName = myUserName;
        gitUserEmail = "${myUserName}@example.com";

        # ---------------------------------------------------------------
        # 🐚 SHELLS & APPS
        # ---------------------------------------------------------------
        terminal = myTerminal;
        shell = myShell;
        browser = myBrowser;
        editor = myEditor;
        fileManager = myFileManager;

        # ---------------------------------------------------------------
        # 🖼️ MONITORS & WALLPAPERS
        # ---------------------------------------------------------------
        monitors = [
          "eDP-1, 1920x1080@60, 0x0, 1"
        ];

        wallpapers = [

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
        keyboardLayout = "us";
        keyboardVariant = "intl";

        weather = "London";
        useFahrenheit = false;
        nixImpure = false;

        timeZone = "Etc/UTC";

      };

      # ⚠️ The following section contains absolutely everything.
      # Most modules are disabled to have a low weight installation
      # It's kept as reference so a user know what could be enabled/disabled
      # Modules always enabled are not defined here
      # Modules enabled by default with "boolOption true" are defined here anyway, allowing "false"

      # ---------------------------------------------------------------
      # 🌐 TOP-LEVEL MODULES
      # ---------------------------------------------------------------
      bluetooth.enable = true;

      cachix = {
        enable = true;
        push = false;
      };

      cosmic.enable = false;
      gnome.enable = false;
      guest.enable = false;
      home-packages.enable = true; # Enabled to enable automatic installation of browser, editor, file manager and terminal based on the host preferences
      hyprland.enable = true; # Enabled to have at least one wm
      kde.enable = false;

      mime.enable = true; # Disabling this would cause the shortcuts that open "browser, editor, file manager" to fail


      nh.enable = true; # Disabling this would cause most nix-related aliases to fail
      niri.enable = false;
      qt.enable = true; # Disabling this would cause graphical inconsistencies

      zram = {
        enable = true; # Enabled because it's beneficial everywhere
        zramPercent = 25;
      };

      # Disabling this would cause massive graphical inconsistencies
      stylix = {
        enable = true;
        # These are host-specific targets exclusion/inclusion. They are optional
        targets = { alacritty.enable = !isCatppuccin; };
      };

      # ---------------------------------------------------------------
      # 🚀 PROGRAMS
      # ---------------------------------------------------------------
      programs.bat.enable = false;
      programs.cosmic.enable = false;
      programs.eza.enable = false;
      programs.fzf.enable = true; # Disabling this would cause some shell aliases to not work

      programs.git = {
        enable = false; # Note git as package is installed anyway, disabling this only means disabling the custom configuration such as setting the user identity
        # These are host-specific git exclusion/inclusion. They are optional
        customGitIgnores = [ ];
      };

      programs.lazygit.enable = false;
      programs.shell-aliases.enable = true; # Enabled for convenience
      programs.starship.enable = false;
      programs.tmux.enable = false;
      programs.walker.enable = true; # Disabling this mean missing an app launcher in hyprland/niri

      programs.waybar = {
        enable = true;

        waybarLayout = {
          "format-en" = "🇺🇸-EN";
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

      programs.zoxide.enable = true; # Disabling this would cause some aliases to not work

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
        enable = true; # Enabled to give the template at least one window manager
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

          "workspace ${appWorkspaces.fileManager} silent, class:^(org.kde.dolphin)$"

          "workspace ${appWorkspaces.browser-Entertainment} silent, class:^(chromium-browser)$"

          "workspace ${appWorkspaces.terminal} silent, class:^(kitty)$"
          "workspace ${appWorkspaces.chat} silent, class:^(vesktop)$"

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
        ];

        extraBinds = [
          "$Mod SHIFT, B, exec, [workspace special:magic] ${myBrowser} --new-window --class scratch-browser"
        ];
      };

      programs.niri = {
        enable = false;
        execOnce = [
          "${myBrowser}"
          "${myEditor}"
          "${myFileManager}"
          "${myTerminal}"
        ];
      };

      programs.gnome = {
        enable = false;
        screenshots = "/home/krit/Pictures/Screenshots";
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)

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
        enable = false;
        pinnedApps = [
          (resolve myBrowser)
          (resolve myEditor)
          (resolve myFileManager)
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
      services.hyprlock.enable = false;
      services.sddm.enable = true; # Without this there would not be a display manager, forcing to use a tty

      services.snapshots = {
        enable = false;
        retention = {
          hourly = "24";
          daily = "7";
          weekly = "4";
          monthly = "3";
          yearly = "2";
        };
      };

      services.tailscale.enable = false;

      services.hypridle = {
        enable = false;
        dimTimeout = 900;
        lockTimeout = 1800;
        screenOffTimeout = 3600;
      };

      services.swaync = {
        enable = false;
        customSettings = {
          "mute-protonvpn" = {
            state = "ignored";
            app-name = ".*Proton.*";
          };
        };
      };

      full-host.services.flatpak.enable = false;
      full-host.services.local-packages.enable = false;
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
        #inputs.nix-sops.nixosModules.sops # Tough an import does not cause the build to fail it's removed for lightness. Enable if used
        inputs.niri.nixosModules.niri

        ./hardware-configuration.nix

      ];

      i18n.defaultLocale = "en_US.UTF-8";

      #users.mutableUsers = false; # Enable this only if the password is setup with sops. This bring the risk of being locked out of the system if enabled without
      users.users.${myUserName} = {
        isNormalUser = true;
        description = "${myUserName}";
        extraGroups = [
          "networkmanager"
          "wheel"
          "input"
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

      # Kept for reference
      /*
        virtualisation.docker.enable = false;
        virtualisation.podman = {
          enable = false;
          dockerCompat = false;
        };
      */

      # Kept for reference
      /*
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
      */

      # Solve Home-manager portal assertion
      environment.pathsToLink = [
        "/share/applications"
        "/share/xdg-desktop-portal"
      ];

      environment.systemPackages = with pkgs; [
        #autotrash # Uncomment if using autotrash
        #docker # Uncomment if using docker
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

        #inputs.nix-sops.homeModules.sops # Tough an import does not cause the build to fail it's removed for lightness. Enable if used

      ];

      home.packages = (with pkgs; [ ]) ++ (with pkgs-unstable; [ ]);

      # Kept for reference
      /*
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
      */
    };

}
