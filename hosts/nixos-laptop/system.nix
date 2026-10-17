{ delib
, pkgs
, ...
}:
delib.host {
  name = "nixos-laptop";

  nixos = {
    system.stateVersion = "25.11";
    time.hardwareClockInLocalTime = true;

    imports = [
      ./hardware-configuration.nix

      # Host-specific sops secrets (common ones live in
      # users/krit/common/toplevel/sops-secrets.nix, enabled via default.nix)
      (
        { config, ... }:
        {
          sops.secrets."krit-local-password".neededForUsers = true;

          users.users.${config.myconfig.constants.user}.hashedPasswordFile = config.sops.secrets.krit-local-password.path;
          users.users.root.hashedPasswordFile = config.sops.secrets.krit-local-password.path;

          # GitHub PAT for nix
          nix.extraOptions = ''
            !include ${config.sops.secrets.github_fg_pat_token_nix.path}
          '';
        }
      )

      # Wire sops secrets to services
      ../../templates/krit/sops/service-wiring.nix
    ];

    sops = {
      defaultSopsFile = ./nixos-laptop-secrets-sops.yaml;
      defaultSopsFormat = "yaml";
      age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    };

    nix.settings.max-jobs = 6;

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

    # Keyboard backlight timeout is set in BIOS setup (no Auto option on this firmware), not here:
    # the dell_laptop als_enabled write is rejected with EINVAL.

    # Adaptive battery charging is set in BIOS setup (Battery Configuration), not here:
    # a BIOS admin password is set, so dell-wmi-sysman writes are rejected (EOPNOTSUPP).

    services.udev.packages = [ pkgs.brightnessctl ];

    # Timer, not a delayed boot unit: see memory/project_laptop_kbd_backlight_restore_workaround.md
    systemd.services.kbd-backlight-restore = {
      description = "Restore keyboard backlight after Dell EC auto-off";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl --device='*::kbd_backlight' set 2";
      };
    };
    systemd.timers.kbd-backlight-restore = {
      description = "Restore keyboard backlight after Dell EC auto-off";
      wantedBy = [ "timers.target" ];
      timerConfig.OnBootSec = "15s";
    };

    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD VA-API backend for Arc/Xe hardware video acceleration
        intel-compute-runtime # OpenCL support
      ];
    };

    environment.systemPackages = [ pkgs.lm_sensors ];
  };
}
