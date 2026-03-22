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

    imports = [
      inputs.niri.nixosModules.niri
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

      ../../templates/krit/specialization/default.nix

      # Config that depends on secrets
      (
        { config, lib, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;

          # ---------------------------------------------------------
          # 🔐 CENTRALIZED SOPS DEFINITIONS
          # ---------------------------------------------------------
          sops.secrets = {
            # Host-specific secrets (from host sops file)
            "krit-local-password".neededForUsers = true;
            borg-passphrase = { };
            borg-private-key = { };
          } // (import ../../templates/krit/sops/common-secrets.nix {
            inherit lib;
            user = myUserName;
            claudeCodeMcpSecrets = config.myconfig.programs.claude-code.mcpSecrets;
          });

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
          myconfig.krit.services.nas.desktop-borg-backup.passphraseFile = config.sops.secrets.borg-passphrase.path;
          myconfig.krit.services.nas.desktop-borg-backup.sshKeyPath = config.sops.secrets.borg-private-key.path;
          myconfig.krit.services.nas.owncloud.secretsFile = config.sops.templates."davfs-secrets".path;

          services.tailscale.authKeyFile = config.sops.secrets.tailscale_key.path;

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

    # Host-specific sops config
    sops.defaultSopsFile = ./nixos-desktop-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # GitHub PAT for nix
    nix.extraOptions = ''
      !include /run/secrets/github_fg_pat_token_nix
    '';

    # Desktop-specific hardware
    boot.binfmt.emulatedSystems = [ "aarch64-linux" ]; # Allow emulation of aarch64-linux
    boot.initrd.kernelModules = [ "amdgpu" ];
    hardware.graphics.enable = true;

    services.logind.settings.Login = {
      HandlePowerKey = "poweroff";
      HandlePowerKeyLongPress = "poweroff";
    };

    environment.pathsToLink = [
      "/share/applications"
      "/share/xdg-desktop-portal"
    ];

    # Desktop-specific packages
    environment.systemPackages = with pkgs; [
      libvdpau-va-gl # Allow VA-GL to be used as a VDPAU backend for hardware video acceleration on AMD GPUs
    ];
  };
}
