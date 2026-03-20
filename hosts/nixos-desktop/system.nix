{ delib
, inputs
, pkgs
, ...
}:
let
  myUserName = "krit";
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    system.stateVersion = "25.11";

    environment.variables = { };

    # Configure host specific impermanence persist
    environment.persistence."/persist" = {
      directories = [
      ];
      files = [
      ];
    };

    # Configure host-specific ssh settings
    programs.ssh = {
      extraConfig = ''
        Host nicol-nas 192.168.1.98 ssh.nicolkrit.ch
          IdentityFile /home/${myUserName}/.ssh/id_github
          IdentitiesOnly yes
          User krit
      '';
    };

    imports = [
      inputs.niri.nixosModules.niri
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

      ../../templates/krit/specialization/default.nix

      # Dynamically generate sops secrets for claude-code MCP from mcpSecrets list
      (
        { config, lib, ... }:
        let
          commonSecrets = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
        in
        {
          sops.secrets = lib.mkIf config.myconfig.programs.claude-code.enable (
            lib.listToAttrs (
              map (s: {
                name = s.sopsSecret;
                value = {
                  sopsFile = commonSecrets;
                  owner = myUserName;
                };
              }) config.myconfig.programs.claude-code.mcpSecrets
            )
          );
        }
      )

      (
        { config, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;

          sops.templates."davfs-secrets" = {
            content = ''
              ${config.sops.placeholder.nas_owncloud_url} ${config.sops.placeholder.nas_owncloud_user} ${config.sops.placeholder.nas_owncloud_pass}
            '';
            owner = "root";
            group = "root";
            mode = "0600";
          };

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
          users.users.root.hashedPasswordFile = config.sops.secrets.krit-local-password.path;

          # ---------------------------------------------------------
          # 🗺️ NIX-TOPOLOGY DEFINITIONS
          # ---------------------------------------------------------
          # TODO: wait to be on teh same network as the nas to implement this
          /*
          topology.networks.home = {
            name = "Krit Home Network";
            cidrv4 = "192.168.1.0/24";
          };

          # 2. Tell topology that this desktop is on the home network
          # (nix-topology auto-detects the interface name, just assign it)
          topology.self.interfaces."*".network = "home";

          # 3. Manually add the NAS so it appears in the diagram!
          topology.nodes.nicol-nas = {
            deviceType = "server";
            interfaces.lan = {
              addresses = [ "192.168.1.98" ];
              network = "home";
            };
          };
          # (Optional) Map a physical connection if the interface name is known:
          # topology.self.interfaces.eth0.physicalConnections = [{ node = "nicol-nas"; interface = "lan"; }];
          */
        }
      )
    ];

    # Override only the formats for numbers, dates, and measurements
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "it_CH.UTF-8"; # Address formatting
      LC_IDENTIFICATION = "it_CH.UTF-8"; # Identification formatting for files (only metadata)
      LC_MEASUREMENT = "it_CH.UTF-8"; # Uses Metric system (km, Celsius)
      LC_MONETARY = "it_CH.UTF-8"; # Uses CHF formatting
      LC_NAME = "it_CH.UTF-8"; # Personal name formatting (Surname Name)
      LC_NUMERIC = "it_CH.UTF-8"; # Swiss number separators
      LC_PAPER = "it_CH.UTF-8"; # Defaults printers to A4
      LC_TELEPHONE = "it_CH.UTF-8"; # Telephone number formatting (e.g. +41 79 123 45 67)
      LC_TIME = "it_CH.UTF-8"; # 24-hour clock and DD.MM.YYYY
    };

    # Setup git signing and allowed signers for the user, and also make the allowed signers available as a home file for use in other contexts (e.g. SSH configuration)
    home-manager.users.${myUserName} =
      { ... }:
      {

        programs.git = {
          enable = true;
          settings = {
            gpg.format = "ssh";
            user.signingKey = "/home/${myUserName}/.ssh/id_github";
            commit.gpgSign = true;

            gpg.ssh.allowedSignersFile = "/home/${myUserName}/.ssh/allowed_signers";
          };
        };

        # 🏠 hosts/nixos-desktop/system.nix (Around line 115)
        home.file.".ssh/allowed_signers".text = ''
          githubgitlabmain.hu5b7@passfwd.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIO4fJZtoawnvuR2D/CAk7fBrioEyhyagheH4RtTaf8gD
        '';
      };
    sops.defaultSopsFile = ./nixos-desktop-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # ---------------------------------------------------------
    # 🔐 CENTRALIZED SOPS DEFINITIONS
    # ---------------------------------------------------------
    sops.secrets =
      let
        commonSecrets = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
      in
      {
        "krit-local-password".neededForUsers = true;


        github_fg_pat_token_nix = {
          sopsFile = commonSecrets;
          mode = "0444";
        };

        github_general_ssh_pub = {
          sopsFile = commonSecrets;
          owner = myUserName;
          path = "/home/${myUserName}/.ssh/id_github.pub";
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

        nas_ssh_key.sopsFile = commonSecrets;
        nas-krit-credentials.sopsFile = commonSecrets;
        nas_owncloud_url.sopsFile = commonSecrets;
        nas_owncloud_user.sopsFile = commonSecrets;
        nas_owncloud_pass.sopsFile = commonSecrets;

        borg-passphrase = { };
        borg-private-key = { };
        cachix-auth-token = { };
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
      tmate
      tree
      unzip
      wget
      zip
      zlib
    ];
  };
}
