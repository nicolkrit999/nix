{
  config,
  pkgs,
  lib,
  vars,
  ...
}:
{
  # home.nix and host-modules are imported from flake.nix
  imports = [
    # Packages specific to this machine
    ./optional/host-packages/default.nix

    # These are manually imported here because they contains aspects that home-manager can not handle alone
    ./optional/host-hm-modules/utilities/logitech.nix # boot
    ./optional/host-hm-modules/utilities/gaming.nix # hardware
    ./optional/host-hm-modules/nas/smb.nix # user
    ./optional/host-hm-modules/nas/borg-backup.nix # user
    ./optional/host-hm-modules/nas/ssh.nix # user
    ./optional/host-hm-modules/nas/owncloud.nix # user

  ]
  ++ (lib.optional (builtins.pathExists ./optional/dev-environments/default.nix) ./optional/dev-environments/default.nix);

  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  # 🌍 LOCALE
  # +++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  i18n.defaultLocale = "en_US.UTF-8";

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
      commonSecrets = ../../common/krit-common-secrets-sops.yaml;
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

  # ---------------------------------------------------------
  # ⚙️ GRAPHICS & FONTS
  # ---------------------------------------------------------
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.graphics.enable = true;

  # ---------------------------------------------------------
  # 👤 USER CONFIGURATION
  # ---------------------------------------------------------
  users.users.${vars.user} = {
    isNormalUser = true;
    description = "Primary user";
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

    hashedPasswordFile = config.sops.secrets.krit-local-password.path;
  };

  # ---------------------------------------------------------
  # 🐳 VIRTUALIZATION & DOCKER
  # Needed because otherwise the group "docker" is not created
  # ---------------------------------------------------------
  virtualisation.docker.enable = true;

  # Limited mtu to make internet faster when enabled
  virtualisation.docker.daemon.settings = {
    "mtu" = 1450;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = false; # Allows Podman to answer to 'docker' commands (false as it clash with docker)
  };

  # ---------------------------------------------------------
  # 🌐 BROWSER
  # ---------------------------------------------------------
  programs.chromium = {
    enable = true;

    extraOpts = {
      "ShowHomeButton" = true;
      "HomepageLocation" = "https://www.youtube.com";
      "HomepageIsNewTabPage" = false;

      # 4 = Always open the URLs listed below (ignores previous session)
      "RestoreOnStartup" = 4;

      "RestoreOnStartupURLs" = [
        "https://www.youtube.com"
        "https://music.youtube.com/"
        "https://glance.nicolkrit.ch"
      ];
    };
  };

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
  ];
}
