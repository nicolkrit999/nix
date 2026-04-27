{ delib
, inputs
, pkgs
, ...
}:
let
  myUserName = "krit";
in
delib.host {
  name = "nixos-laptop";

  nixos = {
    system.stateVersion = "25.11";
    time.hardwareClockInLocalTime = true;

    environment.variables = { };

    # Configure host specific impermanence persist
    environment.persistence."/persist" = {
      directories = [
      ];
      files = [
      ];
    };

    imports = [
      inputs.nix-sops.nixosModules.sops
      ./hardware-configuration.nix

      # Sops secrets definitions
      (
        { config, lib, ... }:
        {
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

          users.users.${myUserName}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
          users.users.root.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
        }
      )

      # Wire sops secrets to services
      ../../templates/krit/sops/service-wiring.nix

      # Other config
      (
        { config, ... }:
        {
          i18n.defaultLocale = config.myconfig.constants.mainLocale;
        }
      )
    ];

    # Host-specific sops config
    sops.defaultSopsFile = ./nixos-laptop-secrets-sops.yaml;
    sops.defaultSopsFormat = "yaml";
    sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];

    # GitHub PAT for nix
    nix.extraOptions = ''
      !include /run/secrets/github_fg_pat_token_nix
    '';

    # Laptop-specific hardware — Intel Arc B390 (12 Xe3 cores, integrated in Panther Lake X7 358H SoC, xe driver)
    hardware.enableRedistributableFirmware = true; # Intel CPU microcode + GPU firmware for Panther Lake
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD VA-API backend for Arc/Xe hardware video acceleration
        intel-compute-runtime # OpenCL support
      ];
    };

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
      lm_sensors # `sensors` command for monitoring temps/fans
    ];
  };
}
