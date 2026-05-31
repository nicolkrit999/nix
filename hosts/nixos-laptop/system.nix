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

            "attic-push-token" = {
              sopsFile = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
              owner = myUserName;
            };
            "cachix-push-token" = {
              sopsFile = ../../users/krit/common/sops/krit-common-secrets-sops.yaml;
              owner = myUserName;
            };
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

    # TEMPORARY WORKAROUND: Override sof-firmware to nixpkgs-unstable (2025.12.2+) for newer DSP firmware
    # (2.13.0.1 → 2.14.1.1) and per-unit CS35L57 calibration files on Dell XPS 16 2026 (Panther Lake).
    # Note: 4-amp topology hypothesis was WRONG — 4 physical CS35L57s = 2 stereo SDCA function instances,
    # so 2amp IS correct. Override kept for DSP firmware improvements only.
    # Remove when nixpkgs 26.05 ships sof-firmware ≥ 2025.12.2, or when UCM2 support lands.
    nixpkgs.overlays = [
      (_final: prev: {
        sof-firmware = inputs.nixpkgs-unstable.legacyPackages.${prev.stdenv.hostPlatform.system}.sof-firmware;
      })
    ];

    # TEMPORARY WORKAROUND: No UCM2 profile for sof-soundwire on Dell XPS 16 2026 (Panther Lake).
    # Without this, PipeWire defaults to Pro 1 (headphone jack PCM) → silence on internal speakers.
    # Confirmed 2026-05-23: upstream NOT fixed — audio only works on Pro 2 (SmartAmp/speakers);
    # Pro 1/5/6/7/31 all produce no sound. Session persistence can mask this across reboots.
    # Available sof-soundwire Pro sinks: 1 (jack), 2 (speakers ✓), 5, 6, 7, 31 (HDMI/DP).
    # Remove this entire block when UCM2 or kernel machine driver support lands for this hardware.
    services.pipewire.wireplumber.extraConfig."50-dell-xps16-speakers" = {
      "monitor.alsa.rules" = [
        {
          "matches" = [{ "device.name" = "alsa_card.pci-0000_00_1f.3-platform-sof_sdw"; }];
          "actions"."update-props"."device.profile" = "pro-audio";
        }
      ];
      "node.rules" = [
        {
          "matches" = [{ "node.name" = "alsa_output.pci-0000_00_1f.3-platform-sof_sdw.pro-output-2"; }];
          "actions"."update-props"."priority.session" = 2000;
        }
      ];
    };

    boot.extraModprobeConfig = ''
      options iwlwifi disable_11be=1 power_save=0 uapsd_disable=1
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
