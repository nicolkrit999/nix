{ delib
, inputs
, lib
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
    # Intel SOF (Sound Open Firmware) — required for Panther Lake audio (CS42L43+CS35L56 via SoundWire).
    # Pinned to v2025.12.2: nixpkgs ships v2025.05.1 which lacks SDCA topology fixes
    # needed for Dell PTL. Audio will remain broken (dummy output) until kernel 7.0+
    # which has ABI 3.29+ and Dell PTL audio quirks. Keep this override for the firmware
    # blobs; revisit when nixpkgs bumps sof-firmware to >= v2025.12.2.
    hardware.firmware = with pkgs; [
      (sof-firmware.overrideAttrs (_old: rec {
        version = "2025.12.2";
        src = pkgs.fetchurl {
          url = "https://github.com/thesofproject/sof-bin/releases/download/v${version}/sof-bin-${version}.tar.gz";
          hash = "sha256-Uz9j46bZTAnOBaeCZXtnX6aD/yB4fAl5Imz1Y+x59Rc=";
        };
      }))
      alsa-firmware
    ];
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD VA-API backend for Arc/Xe hardware video acceleration
        intel-compute-runtime # OpenCL support
      ];
    };

    # Panther Lake is too new for thermald's thermal profile database — without a matching
    # profile it applies conservative fallback limits that throttle CPU+GPU unnecessarily.
    # mkForce overrides auto-cpufreq.nix which enables thermald by default.
    services.thermald.enable = lib.mkForce false;

    # KERNEL OVERRIDE — blocked until nixpkgs fixes modules-shrunk for kernel 7.0 (aes_generic
    # is built-in in 7.0 but the initrd builder expects it as a loadable .ko, breaking LUKS).
    # Uncomment once linuxPackages_latest ships 7.0+ with the fix:
    # boot.kernelPackages = lib.mkForce pkgs.linuxPackages_latest;

    # Panther Lake (2025/2026) uses Intel Modern Standby (S0ix / s2idle).
    boot.kernelParams = [
      "mem_sleep_default=s2idle"
      "rtc_cmos.use_acpi_alarm=1" # Use ACPI alarm for RTC wakeup (prevents s2idle freeze)
    ];

    # TEMPORARY WORKAROUND — Panther Lake Xe3 lid-close freeze (kernel 6.19.x)
    # The Intel Xe driver freezes during suspend/resume triggered by lid close.
    # Previous attempts that FAILED: xe.enable_display_rps=0, acpid DPMS-off-before-suspend.
    # Nuclear option: ignore lid for suspend so closing it never triggers sleep.
    # Instead, acpid locks the session on lid close (via loginctl → hypridle → hyprlock).
    # The laptop stays running with lid closed — wasteful but avoids the freeze and stays locked.
    # Manual suspend from the DE power menu still works (but may still freeze).
    # REMOVE THIS (logind ignore + acpid lock handler) when kernel 7.0+ lands with Xe3 suspend/resume fixes.
    services.logind.settings.Login.HandleLidSwitch = "ignore";
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";
    services.logind.settings.Login.HandleLidSwitchDocked = "ignore";

    services.acpid = {
      enable = true;
      handlers.lid-lock = {
        event = "button/lid.*";
        action = ''
          # Lock session on lid close so the laptop is protected even though we skip suspend.
          LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | head -1)
          if echo "$LID_STATE" | grep -q "closed"; then
            USER_ID=$(id -u "${myUserName}" 2>/dev/null) || exit 1
            XDG_RUNTIME_DIR="/run/user/$USER_ID"
            # loginctl lock-session triggers hypridle's lock_cmd (universal-lock → hyprlock)
            runuser -u "${myUserName}" -- env XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" loginctl lock-session
          fi
        '';
      };
    };

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
    ];
  };
}
