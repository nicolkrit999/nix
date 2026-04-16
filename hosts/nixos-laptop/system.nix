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
    # Intel SOF (Sound Open Firmware) — Panther Lake audio (CS42L43+CS35L56 via SoundWire).
    # AUDIO DOES NOT WORK with or without this override. Tested both:
    #   - WITH pinned sof-firmware v2025.12.2: device detected as "sof-soundwire Stereo",
    #     ABI 3.29 matches kernel, but NO sound output. Speakers, 3.5mm mic, external
    #     monitor audio, and Bluetooth audio all broken/missing.
    #   - WITHOUT (nixpkgs default v2025.05.1): ABI mismatch, dummy output only.
    # Waiting for future kernel/firmware update to fix Dell PTL topology/routing.
    # hardware.firmware = with pkgs; [
    #   (sof-firmware.overrideAttrs (_old: rec {
    #     version = "2025.12.2";
    #     src = pkgs.fetchurl {
    #       url = "https://github.com/thesofproject/sof-bin/releases/download/v${version}/sof-bin-${version}.tar.gz";
    #       hash = "sha256-Uz9j46bZTAnOBaeCZXtnX6aD/yB4fAl5Imz1Y+x59Rc=";
    #     };
    #   }))
    #   alsa-firmware
    # ];
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD VA-API backend for Arc/Xe hardware video acceleration
        intel-compute-runtime # OpenCL support
      ];
    };

    # COMMENTED OUT for kernel 7.0 testing — thermald may have PTL support now.
    # Panther Lake is too new for thermald's thermal profile database — without a matching
    # profile it applies conservative fallback limits that throttle CPU+GPU unnecessarily.
    # mkForce overrides auto-cpufreq.nix which enables thermald by default.
    # services.thermald.enable = lib.mkForce false;

    # WORKAROUND: kernel 7.0 compiles aes_generic as built-in (not a .ko module), but
    # NixOS's luksroot.nix adds it to boot.initrd.luks.cryptoModules by default. The
    # modules-shrunk builder then fails because it can't find aes_generic.ko.
    # Fix: override cryptoModules to exclude aes_generic (it's already in the kernel).
    # REMOVE THIS when nixpkgs luksroot.nix is updated to handle built-in modules.
    boot.initrd.luks.cryptoModules = [
      "aes"
      # "aes_generic"  # built-in in kernel 7.0+, no .ko exists
      "blowfish"
      "twofish"
      "serpent"
      "cbc"
      "xts"
      "lrw"
      "sha1"
      "sha256"
      "sha512"
      "af_alg"
      "algif_skcipher"
    ];

    # COMMENTED OUT for kernel 7.0 testing — s2idle may work properly by default now.
    # Panther Lake (2025/2026) uses Intel Modern Standby (S0ix / s2idle).
    # boot.kernelParams = [
    #   "mem_sleep_default=s2idle"
    #   "rtc_cmos.use_acpi_alarm=1" # Use ACPI alarm for RTC wakeup (prevents s2idle freeze)
    # ];

    # COMMENTED OUT for kernel 7.0 testing — Xe3 suspend/resume may be fixed.
    # TEMPORARY WORKAROUND — Panther Lake Xe3 lid-close freeze (kernel 6.19.x)
    # The Intel Xe driver freezes during suspend/resume triggered by lid close.
    # Previous attempts that FAILED: xe.enable_display_rps=0, acpid DPMS-off-before-suspend.
    # Nuclear option: ignore lid for suspend so closing it never triggers sleep.
    # Instead, acpid locks the session on lid close (via loginctl → hypridle → hyprlock).
    # The laptop stays running with lid closed — wasteful but avoids the freeze and stays locked.
    # Manual suspend from the DE power menu still works (but may still freeze).
    # REMOVE THIS (logind ignore + acpid lock handler) when kernel 7.0+ lands with Xe3 suspend/resume fixes.
    # services.logind.settings.Login.HandleLidSwitch = "ignore";
    # services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    # services.logind.settings.Login.HandleLidSwitchDocked = "ignore";


    # services.acpid = {
    #   enable = true;
    # };

    # COMMENTED OUT for kernel 7.0 testing — auto-cpufreq/thermald may handle this properly now.
    # Force ACPI platform profile to "balanced" at boot — Dell firmware then applies its
    # quieter fan curve designed for the XPS chassis. Without this, auto-cpufreq sets
    # "custom" which bypasses Dell's thermal management and can cause louder fan behavior.
    # systemd.tmpfiles.rules = [
    #   "w /sys/firmware/acpi/platform_profile - - - - balanced"
    # ];

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
      lm_sensors # `sensors` command for monitoring temps/fans
    ];
  };
}
