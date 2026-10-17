{ delib
, pkgs
, ...
}:
let
  kbdDevice = "--device=*::kbd_backlight";

  kbdRecord = pkgs.writeShellApplication {
    name = "kbd-backlight-record";
    runtimeInputs = [ pkgs.brightnessctl pkgs.coreutils ];
    text = ''
      brightnessctl ${kbdDevice} get > "$XDG_RUNTIME_DIR/kbd-backlight-level"
    '';
  };

  kbdRelight = pkgs.writeShellApplication {
    name = "kbd-backlight-relight";
    runtimeInputs = [ pkgs.brightnessctl pkgs.coreutils ];
    text = ''
      state="$XDG_RUNTIME_DIR/kbd-backlight-level"
      [ -r "$state" ] || exit 0
      recorded=$(cat "$state")
      current=$(brightnessctl ${kbdDevice} get)
      if [ "$recorded" -gt 0 ] && [ "$current" -eq 0 ]; then
        brightnessctl ${kbdDevice} set "$recorded"
      fi
    '';
  };

  kbdTriggers = pkgs.writeShellApplication {
    name = "kbd-backlight-triggers";
    runtimeInputs = [ pkgs.brightnessctl pkgs.coreutils ];
    text = ''
      led=/sys/class/leds/dell::kbd_backlight
      [ -d "$led" ] || exit 0
      for name in keyboard touchpad pointing_stick; do
        if ! grep -qE "(^| )[-+]$name( |$)" "$led/start_triggers"; then
          echo "trigger $name not offered, skipped"
          continue
        fi
        echo "+$name" > "$led/start_triggers" || echo "write failed: +$name"
        echo "start_triggers: $(cat "$led/start_triggers" || true)"
      done
      brightnessctl ${kbdDevice} set 2 || echo "write failed: brightness 2"
    '';
  };

  kbdIdleConfig = pkgs.writeText "hypridle-kbd-backlight.conf" ''
    listener {
      timeout = 50
      on-timeout = ${kbdRecord}/bin/kbd-backlight-record
      on-resume = ${kbdRelight}/bin/kbd-backlight-relight
    }
  '';
in
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

    services.udev = {
      packages = [ pkgs.brightnessctl ];
      extraRules = ''
        ACTION=="add", SUBSYSTEM=="leds", KERNEL=="dell::kbd_backlight", TAG+="systemd", ENV{SYSTEMD_WANTS}="kbd-backlight-triggers.service"
      '';
    };

    systemd = {
      services = {
        kbd-backlight-triggers = {
          description = "Make the Dell firmware relight the keyboard backlight on activity";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${kbdTriggers}/bin/kbd-backlight-triggers";
          };
        };

        kbd-backlight-triggers-resume = {
          description = "Re-apply keyboard backlight triggers after resume";
          wantedBy = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
          after = [ "suspend.target" "hibernate.target" "hybrid-sleep.target" "suspend-then-hibernate.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${kbdTriggers}/bin/kbd-backlight-triggers";
          };
        };

        # Timer, not a delayed boot unit: see memory/project_laptop_kbd_backlight_restore_workaround.md
        kbd-backlight-restore = {
          description = "Restore keyboard backlight after Dell EC auto-off";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.brightnessctl}/bin/brightnessctl --device='*::kbd_backlight' set 2";
          };
        };
      };

      timers.kbd-backlight-restore = {
        description = "Restore keyboard backlight after Dell EC auto-off";
        wantedBy = [ "timers.target" ];
        timerConfig.OnBootSec = "15s";
      };

      user.services.kbd-backlight-relight = {
        description = "Relight the keyboard backlight after the firmware idle auto-off";
        wantedBy = [ "graphical-session.target" ];
        partOf = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        unitConfig.ConditionPathExistsGlob = "/sys/class/leds/*::kbd_backlight";
        serviceConfig = {
          ExecStart = "${pkgs.hypridle}/bin/hypridle -c ${kbdIdleConfig}";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
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
