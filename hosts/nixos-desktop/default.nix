{ delib, ... }:
delib.host {
  name = "nixos-desktop";
  type = "desktop";

  # ---------------------------------------------------------------
  # ⚙️ VERSIONS & SYSTEM IDENTITY (From variables.nix)
  # ---------------------------------------------------------------
  homeManagerSystem = "x86_64-linux";
  nixos.system.stateVersion = "25.11";
  home.home.stateVersion = "25.11";

  # ---------------------------------------------------------------
  # 🚀 SHARED CONFIGURATION & MODULE TOGGLES
  # ---------------------------------------------------------------
  shared.myconfig = {
    # 🧠 CORE CONSTANTS (Replacing variables.nix values)
    constants = {
      # User Identity
      username = "krit";
      gitUserName = "nicolkrit999";
      gitUserEmail = "githubgitlabmain.hu5b7@passfwd.com";

      # Shells & Apps
      terminal = "kitty";
      shell = "fish";
      browser = "librewolf";
      editor = "nvim";
      fileManager = "yazi";

      # Advanced System Constants
      zramPercent = 25;
      snapshotRetention = {
        hourly = "24";
        daily = "7";
        weekly = "4";
        monthly = "3";
        yearly = "2";
      };

      # 🖼️ MONITORS & WALLPAPERS
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

      # 🎨 THEMING
      theme = {
        polarity = "dark";
        base16Theme = "catppuccin-mocha";
        catppuccin = true;
        catppuccinFlavor = "mocha";
        catppuccinAccent = "teal";
      };
    };

    # 🎛️ MODULE TOGGLES (Translating your boolean flags)
    # Desktop Environments
    programs.hyprland.enable = true;
    programs.niri.enable = true;
    programs.gnome.enable = true;
    programs.kde.enable = true;
    programs.cosmic.enable = true;

    # Bars & Features
    programs.waybar.enable = true;
    programs.swaync.enable = true;
    krit.guest.enable = true;

    # Networking & Services
    services.tailscale.enable = true;
    services.bluetooth.enable = true;
    services.samba.enable = true;
    services.flatpak.enable = true;

    # Sub-WM configurations (Disabled in your config)
    krit.hyprlandCaelestia.enable = false;
    krit.hyprlandNoctalia.enable = false;
    krit.niriNoctalia.enable = false;

    programs.gnome = {
      enable = true;
      screenshots = "/home/krit/Pictures/Screenshots";
      pinnedApps = [
        "firefox.desktop"
        "kitty.desktop"
      ];
    };
  };

  # ---------------------------------------------------------------
  # ⚙️ SYSTEM-LEVEL CONFIGURATIONS (From configuration.nix)
  # ---------------------------------------------------------------
  nixos =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [
        ./hardware-configuration.nix
        ./optional/default.nix
      ];

      i18n.defaultLocale = "en_US.UTF-8";

      # 🔐 SOPS CONFIGURATION
      sops.defaultSopsFile = ./optional/host-sops-nix/nixos-desktop-secrets-sops.yaml;
      sops.defaultSopsFormat = "yaml";
      sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      sops.secrets = {
        "krit-local-password".neededForUsers = true;
        # Add the rest of your common github secrets here...
      };

      # 📦 SYSTEM PACKAGES
      environment.systemPackages = with pkgs; [
        autotrash
        docker
        distrobox
        fd
        gnupg
        pinentry-qt
        pinentry-curses
        libvdpau-va-gl
        logiops
        pay-respects
        pokemon-colorscripts
        stow
        tree
        unzip
        wget
        zip
        zlib
      ];

      # 🗑️ AUTOTRASH SYSTEMD SERVICE
      systemd.services.cleanup_trash = {
        description = "Automatic trash cleanup";
        environment = {
          "HOME" = "/home/krit";
        };
        serviceConfig = {
          Type = "oneshot";
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
    };

  # ---------------------------------------------------------------
  # 🏠 USER-LEVEL CONFIGURATIONS (From home.nix)
  # ---------------------------------------------------------------
  home =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    {
      imports = [
        ./optional/general-hm-modules
        ./optional/host-hm-modules
      ];

      # 🌐 VIVALDI DESKTOP ENTRY & WRAPPER
      xdg.desktopEntries.vivaldi = {
        name = "Vivaldi";
        genericName = "Web Browser";
        exec = "/home/krit/.local/bin/vivaldi %U";
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
          # We trick Vivaldi into thinking it's in GTK to stop it from looking for KWallet
          exec env QT_QPA_PLATFORMTHEME=gtk3 vivaldi "$@"
        '';
      };
    };
}
