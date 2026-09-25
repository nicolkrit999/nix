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

      # Host-specific sops secrets (common ones live in
      # users/krit/common/toplevel/sops-secrets.nix, enabled via default.nix)
      (
        { config, ... }:
        {
          sops.secrets."krit-local-password".neededForUsers = true;

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

    nix.settings.max-jobs = 6;

    boot.extraModprobeConfig = ''
      options iwlwifi power_save=0 uapsd_disable=1
    '';

    # Backport of the upstream fix for the intel_cvs driver claiming the GPIO
    # shared with all 4 CS35L57 speaker amps, killing the whole SOF/SoundWire
    # sound card (thesofproject/linux#5940). Remove once the tracked kernel
    # includes this fix.
    boot.kernelPatches = [
      {
        name = "intel-cvs-wake-irq";
        patch = ./intel-cvs-wake-irq.patch;
      }
    ];

    # Ambient-light keyboard backlight is set in BIOS setup (Keyboard Illumination = Auto), not here:
    # this firmware rejects the dell_laptop als_enabled write with EINVAL.

    # Adaptive battery charging is set in BIOS setup (Battery Configuration), not here:
    # a BIOS admin password is set, so dell-wmi-sysman writes are rejected (EOPNOTSUPP).

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
      lm_sensors # Tools for reading hardware sensors - maintained fork
    ];
  };
}
