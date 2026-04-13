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

    # Laptop-specific hardware — Intel Arc (Panther Lake iGPU, xe driver)
    hardware.enableRedistributableFirmware = true; # Enables Intel CPU microcode updates (important for new Panther Lake platform)
    # Intel SOF (Sound Open Firmware) — required for Panther Lake audio.
    # The snd_sof_pci_intel_ptl kernel driver loads but immediately fails without
    # these firmware blobs; hardware.enableRedistributableFirmware does not include them.
    hardware.firmware = with pkgs; [ sof-firmware ];
    hardware.graphics = {
      enable = true;
      extraPackages = with pkgs; [
        intel-media-driver # iHD VA-API backend for Arc/Xe hardware video acceleration
        intel-compute-runtime # OpenCL support
      ];
    };

    # Panther Lake is too new for thermald's thermal profile database — without a matching
    # profile it applies conservative fallback limits that throttle CPU+GPU unnecessarily.
    services.thermald.enable = lib.mkForce false;

    # Panther Lake (2025/2026) uses Intel Modern Standby (S0ix / s2idle).
    # Without this, the kernel defaults to S3 deep sleep which this hardware does not
    # support — causing a freeze on resume. s2idle keeps the CPU in a shallow idle loop
    # so the Intel Xe driver can properly save/restore display state.
    boot.kernelParams = [ "mem_sleep_default=s2idle" ];

    # acpid handles all lid events at the system level — works regardless of compositor
    # (Hyprland, Niri, KDE, GNOME, etc.). Logind is told to ignore lid events so
    # it doesn't race with acpid.
    # KDE and GNOME listen to ACPI events directly via upower/powerdevil/gsd-power,
    # so setting logind to "ignore" does NOT affect their built-in clamshell handling.
    services.logind.settings.Login.HandleLidSwitch = "ignore";
    services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore";

    services.acpid = {
      enable = true;
      handlers.lid-switch = {
        event = "button/lid.*";
        action = ''
          USER_NAME="${myUserName}"
          USER_ID=$(id -u "$USER_NAME" 2>/dev/null) || exit 1
          XDG_RUNTIME_DIR="/run/user/$USER_ID"
          PATH="/run/current-system/sw/bin:$PATH"

          # Detect active Wayland socket from the running compositor process
          COMPOSITOR_PID=$(pgrep -u "$USER_NAME" -x "Hyprland" 2>/dev/null || pgrep -u "$USER_NAME" -x "niri" 2>/dev/null | head -1)
          if [ -n "$COMPOSITOR_PID" ]; then
            WAYLAND_DISPLAY=$(tr '\0' '\n' < /proc/$COMPOSITOR_PID/environ 2>/dev/null | grep "^WAYLAND_DISPLAY=" | cut -d= -f2-)
          fi
          WAYLAND_DISPLAY=''${WAYLAND_DISPLAY:-wayland-1}

          # Check if lid is closing or opening
          LID_STATE=$(cat /proc/acpi/button/lid/*/state 2>/dev/null | head -1)

          if echo "$LID_STATE" | grep -q "closed"; then
            # Check for connected external displays (anything that is not eDP or LVDS)
            EXTERNAL=$(find /sys/class/drm -name "status" 2>/dev/null | \
              grep -Eiv "eDP|LVDS" | \
              xargs grep -l "^connected" 2>/dev/null | head -1)

            if [ -n "$EXTERNAL" ]; then
              # External monitor(s) active: clamshell — disable internal display, keep running
              runuser -u "$USER_NAME" -- env \
                XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
                WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
                PATH="$PATH" \
                sh -c '
                  if hyprctl monitors -j >/dev/null 2>&1; then
                    hyprctl keyword monitor eDP-1,disable
                  elif niri msg outputs >/dev/null 2>&1; then
                    niri msg output eDP-1 off
                  fi
                '
            else
              # No external monitors: suspend normally (s2idle handles resume correctly)
              systemctl suspend
            fi
          else
            # Lid opened: re-enable the internal display
            runuser -u "$USER_NAME" -- env \
              XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
              WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
              PATH="$PATH" \
              sh -c '
                if hyprctl monitors -j >/dev/null 2>&1; then
                  hyprctl keyword monitor eDP-1,3200x2000@120,0x0,1.6
                elif niri msg outputs >/dev/null 2>&1; then
                  niri msg output eDP-1 on
                fi
              '
          fi
        '';
      };
    };

    # Laptop-specific packages
    environment.systemPackages = with pkgs; [
    ];
  };
}
