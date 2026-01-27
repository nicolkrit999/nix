{
  config,
  pkgs,
  lib,
  vars,
  ...
}:
{

  imports = [
    # Common krit modules
    # This import common system-wide modules
    ../../common/krit/modules/default.nix

    # Local modules
    # This import host-specific modules
    ./optional/default.nix
  ];

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🌍 LOCALE
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  i18n.defaultLocale = "en_US.UTF-8";

  /*
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # 🔐 SOPS CONFIGURATION
    # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    # 1. DEFAULT SOURCE (Host Specific)
    sops.defaultSopsFile = ./optional/host-sops-nix/nixos-desktop-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

    # 2. GLOBAL SECRETS DEFINITION
    sops.secrets =
      let
        commonSecrets = ../../common/krit/sops/krit-common-secrets-sops.yaml;
      in
      {
        # LOCAL SECRETS:
        # Loc-1. Local User password
        "krit-local-password".neededForUsers = true;

        # COMMON SECRETS:
        # Comm-3
        github_fg_pat_token_nix = {
          sopsFile = commonSecrets;
          mode = "0444";
        };
        # Comm-1
        github_general_ssh_key = {
          sopsFile = commonSecrets;
          owner = vars.user;
          path = "/home/${vars.user}/.ssh/id_github";
        };

        # Comm-4
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
      };

    # Tell Nix to read the Github token
    nix.extraOptions = ''
      !include ${config.sops.secrets.github_fg_pat_token_nix.path}
    '';
    # ---------------------------------------------------------
    # 🔧 CONFIGURE SSH TO USE THE KEY
    # ---------------------------------------------------------
    programs.ssh = {
      extraConfig = ''
        Host github.com
          IdentityFile ${config.sops.secrets.github_general_ssh_key.path}
      '';
    };
  */

  # ---------------------------------------------------------
  # ⚙️ GRAPHICS & FONTS
  # ---------------------------------------------------------
  hardware.graphics.enable = true;

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  #users.mutableUsers = false; # Owerwrite manual password changes

  users.users.${vars.user} = {
    isNormalUser = true;
    description = "${vars.user}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "input"
      "docker"
      "podman"
      "video"
      "audio"
    ];
    # Required for rootless Podman/Distrobox
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

    # FIXME: sops not added yet
    #hashedPasswordFile = config.sops.secrets.krit-local-password.path;
  };

  # ---------------------------------------------------------
  # 🐳 VIRTUALIZATION & DOCKER
  # Needed because otherwise the group "docker" is not created
  # ---------------------------------------------------------
  virtualisation.docker.enable = false;

  # Limited mtu to make internet faster when enabled
  virtualisation.docker.daemon.settings = {
    "mtu" = 1450;
  };

  virtualisation.podman = {
    enable = false;
    dockerCompat = false; # Allows Podman to answer to 'docker' commands (false as it clash with docker)
  };

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

  # ---------------------------------------------------------
  # 🗑️ AUTO TRASH CLEANUP
  # ---------------------------------------------------------
  # 2. Define the cleanup service
  systemd.services.cleanup_trash = {
    description = "Clean up trash older than 30 days";
    serviceConfig = {
      Type = "oneshot";
      User = vars.user;
      Environment = "HOME=/home/${vars.user}";
      ExecStart = "${pkgs.autotrash}/bin/autotrash -d 30";
    };
  };

  # 3. Schedule it to run daily
  systemd.timers.cleanup_trash = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily"; # Runs once every 24h
      Persistent = true; # Run immediately if the computer was off during the scheduled time
    };
  };

  environment.systemPackages = with pkgs; [
    # docker # Required when virtualisation.docker.enable is true
    pokemon-colorscripts # Used in shell aliases dotfiles
    stow # Used to manage my dotfiles repo
    tree # Display directory structure as a tree
    unzip # Extraction utility for .zip files. It is used by programs to compress/decompress data.
    wget # Network downloader utility
    zip # Compression utility for .zip files. It is used by programs to compress/decompress data.
    zlib # Compression utility for .zip files. It is used by programs to compress/decompress data.
  ];
}
