{
  pkgs,
  lib,
  vars,
  ...
}:
let

  # 🛡️ FALLBACK LOGIC
  # If vars.idleConfig is null (not defined in flake), use these defaults.
  # If it is defined, merge it with defaults to ensure no keys are missing.
  cfg = {
    enable = true;
    dimTimeout = 600; # 10m
    lockTimeout = 1800; # 30m
    screenOffTimeout = 3600; # 60m
    suspendTimeout = 7200; # 2h
  }
  // (if vars.idleConfig != null then vars.idleConfig else { });

in
{
  config = lib.mkIf (vars.hyprland or false) {
    services.hypridle = {
      enable = cfg.enable;

      settings = {
        general = {
          before_sleep_cmd = "loginctl lock-session";
          after_sleep_cmd = "hyprctl dispatch dpms on";
          ignore_dbus_inhibit = false;
          lock_cmd = "pidof hyprlock || hyprlock";
        };

        listener = [
          # Dim Screen
          {
            timeout = cfg.dimTimeout;
            on-timeout = "brightnessctl -s set 30";
            on-resume = "brightnessctl -r";
          }

          # Lock Screen
          {
            timeout = cfg.lockTimeout;
            on-timeout = "loginctl lock-session";
          }

          # Turn Off Monitor
          {
            timeout = cfg.screenOffTimeout;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume = "hyprctl dispatch dpms on";
          }

          # Suspend System
          {
            timeout = cfg.suspendTimeout;
            on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };
}
