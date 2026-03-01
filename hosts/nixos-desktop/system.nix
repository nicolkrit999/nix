{
  delib,
  inputs,
  pkgs,
  lib,
  ...
}:
let
  myUserName = "krit";
in
delib.host {
  name = "nixos-desktop";

  nixos = {
    system.stateVersion = "25.11";

    imports = [
      inputs.catppuccin.nixosModules.catppuccin
      inputs.niri.nixosModules.niri
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

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
          kritpio.nicol@student.supsi.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66
        '';
      };
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

        # 1. School specialization Private Key
        school_ssh_key = {
          sopsFile = commonSecrets;
          owner = myUserName;
          path = "/home/${myUserName}/.ssh/id_school";
        };

        # 2. School specialization Public Key
        school_ssh_pub = {
          sopsFile = commonSecrets;
          owner = myUserName;
          path = "/home/${myUserName}/.ssh/id_school.pub";
        };

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

    # 🎓 SCHOOL SPECIALISATION
    specialisation.school.configuration = {
      system.nixos.tags = [ "school" ];

      # Clear default profile behaviour
      myconfig.programs.hyprland.execOnce = lib.mkForce [ ]; # Disable startup apps in hyprland
      myconfig.programs.niri.execOnce = lib.mkForce [ ]; # Disable startup apps in niri
      myconfig.programs.hyprland.windowRules = lib.mkForce [ ]; # Disable forced workspaces

      # 2. Home Manager Overrides for the School Environment
      home-manager.users.${myUserName} =
        { pkgs, lib, ... }:
        {
          nixpkgs.config.allowUnfree = true;

          home.file.".ssh/allowed_signers".text = lib.mkForce ''
            kritpio.nicol@student.supsi.ch ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBRKQLjixO72qgAc64gzJwsmOdoNQs+KkQg8GewHnm66 kritpio.nicol@student.supsi.ch
          '';

          # Setup git identity and GPG signing with the school specialization key
          programs.git = {
            enable = true;
            settings = {
              user.email = lib.mkForce "kritpio.nicol@student.supsi.ch";
              user.name = lib.mkForce "nicolkrit999-uni";
              gpg.format = lib.mkForce "ssh";
              gpg.ssh.allowedSignersFile = "/home/${myUserName}/.ssh/allowed_signers";

              user.signingkey = lib.mkForce "/home/${myUserName}/.ssh/id_school";
              commit.gpgSign = lib.mkForce true;
            };
            signing = lib.mkForce {
              key = "/home/${myUserName}/.ssh/id_school";
              signByDefault = true;
            };
          };

          # 🎓 SSH Setup: Force student identity and block personal keys
          programs.ssh = {
            enable = true;
            enableDefaultConfig = lib.mkForce false;
            matchBlocks = {
              "github.com" = lib.mkForce {
                hostname = "github.com";
                identityFile = "/home/${myUserName}/.ssh/id_school";
                identitiesOnly = true;
                extraOptions = {
                  "PubkeyAuthentication" = "yes";
                };
              };
              "gitlab.com" = lib.mkForce {
                hostname = "gitlab.com";
                identityFile = "/home/${myUserName}/.ssh/id_school";
                identitiesOnly = true;
              };
              "gitlab-edu.supsi.ch" = lib.mkForce {
                hostname = "gitlab-edu.supsi.ch";
                identityFile = "/home/${myUserName}/.ssh/id_school";
                identitiesOnly = true;
              };
            };
          };

          # 🐚 Workspace Alias
          programs.fish.shellAliases = {
            school = "cd ~/.school-workspace";
          };
          programs.bash.shellAliases = {
            school = "cd ~/.school-workspace";
          };
          programs.zsh.shellAliases = {
            school = "cd ~/.school-workspace";
          };

          # ------------------------------------------------------------
          # PROGRESSIVE WEB APPS & ISOLATED APPS
          # ------------------------------------------------------------
          xdg.desktopEntries =
            let
              makeSchoolPwa = name: url: icon: startupClass: {
                name = "school-pwa-${builtins.replaceStrings [ " " ] [ "-" ] (lib.toLower name)}";
                value = {
                  name = name;
                  genericName = "School Web App";
                  comment = "Launch ${name}";
                  exec = "brave-school --app=\"${url}\" --password-store=gnome";
                  icon = icon;
                  settings = {
                    StartupWMClass = startupClass;
                  };
                  terminal = false;
                  type = "Application";
                  categories = [ "Education" ];
                  mimeType = [
                    "x-scheme-handler/https"
                    "x-scheme-handler/http"
                  ];
                };
              };
            in
            builtins.listToAttrs [
              (makeSchoolPwa "SUPSI Portal" "https://portalestudenti.supsi.ch/" "education"
                "brave-portalestudenti.supsi.ch__-Default"
              )
              (makeSchoolPwa "iCorsi" "https://www.icorsi.ch/" "applications-education"
                "brave-www.icorsi.ch__-Default"
              )
              (makeSchoolPwa "School OwnCloud" "https://owncloud.nicolkrit.ch/" "folder-cloud"
                "brave-owncloud.nicolkrit.ch__-Default"
              )
              (makeSchoolPwa "NotebookLM" "https://notebooklm.google.com/" "utilities-terminal"
                "brave-notebooklm.google.com__-Default"
              )
              (makeSchoolPwa "USI Rooms" "https://usirooms.xyz/" "office-calendar" "brave-usirooms.xyz__-Default")
            ];

          home.packages = [
            (pkgs.writeShellScriptBin "brave-school" ''exec ${pkgs.brave}/bin/brave --user-data-dir=$HOME/.config/BraveSoftware/School "$@"'')
            (pkgs.makeDesktopItem {
              name = "brave-school";
              desktopName = "Brave (School)";
              exec = "brave-school %U";
              icon = "brave";
            })

            (pkgs.writeShellScriptBin "vscode-school" ''exec ${pkgs.vscode}/bin/code --user-data-dir=$HOME/.config/Code-School --extensions-dir=$HOME/.vscode-school/extensions "$@"'')
            (pkgs.makeDesktopItem {
              name = "vscode-school";
              desktopName = "VSCode (School)";
              exec = "vscode-school %F";
              icon = "vscode";
            })

            (pkgs.writeShellScriptBin "idea-school" ''
              export XDG_CONFIG_HOME=$HOME/.config/school-env
              export XDG_DATA_HOME=$HOME/.local/share/school-env
              export XDG_CACHE_HOME=$HOME/.cache/school-env
              exec ${pkgs.jetbrains.idea}/bin/idea "$@"
            '')
            (pkgs.makeDesktopItem {
              name = "idea-school";
              desktopName = "IDEA (School)";
              exec = "idea-school";
              icon = "idea";
            })

            (pkgs.writeShellScriptBin "tkgate-school" ''exec distrobox enter ubuntu -- tkgate "$@"'')
            (pkgs.makeDesktopItem {
              name = "tkgate-school";
              desktopName = "tkGate (Ubuntu)";
              exec = "tkgate-school";
              icon = "tkgate";
            })
          ];
        };
    };

  };
}
