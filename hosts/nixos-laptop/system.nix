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
    time.hardwareClockInLocalTime = true; # Fix windows dual boot time error

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

    # TEST (commented out to check upstream fix): kernel 7.0 compiles aes_generic
    # as built-in (not a .ko module), but NixOS's luksroot.nix added it to
    # boot.initrd.luks.cryptoModules by default — modules-shrunk builder failed
    # because it couldn't find aes_generic.ko. We overrode cryptoModules to exclude it.
    #
    # IF BUILD FAILS with "aes_generic.ko not found" or similar: nixpkgs hasn't fixed
    # luksroot.nix yet — uncomment this block to restore the workaround.
    # IF BUILD SUCCEEDS: the upstream fix landed, this override can be deleted permanently.
    #
    # boot.initrd.luks.cryptoModules = [
    #   "aes"
    #   # "aes_generic"  # built-in in kernel 7.0+, no .ko exists
    #   "blowfish"
    #   "twofish"
    #   "serpent"
    #   "cbc"
    #   "xts"
    #   "lrw"
    #   "sha1"
    #   "sha256"
    #   "sha512"
    #   "af_alg"
    #   "algif_skcipher"
    # ];

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
      lm_sensors # `sensors` command for monitoring temps/fans
    ];
  };
}
