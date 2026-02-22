{
  delib,
  inputs,
  pkgs,
  lib,
  ...
}:
delib.module {
  name = "services.hypridle";

  options.services.hypridle = with delib; {
    enable = boolOption true;
    dimTimeout = intOption 300;
    lockTimeout = intOption 330;
    screenOffTimeout = intOption 360;
  };

  home.ifEnabled =
    {
      cfg,
      myconfig,
      ...
    }:
    let
      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

      universalLock = pkgs.writeShellScriptBin "universal-lock" ''
        if pgrep -f "noctalia-shell" > /dev/null; then
           ${noctaliaPkg}/bin/noctalia-shell ipc call lockScreen lock
           exit 0
        fi
        if command -v caelestiaLogout > /dev/null; then
           caelestiaLogout lock
           exit 0
        fi
        if command -v hyprlock > /dev/null; then
           pidof hyprlock || hyprlock
           exit 0
        fi
      '';

      # 🛠️ FIX: Removed .constants to check the actual host config
      isWmEnabled =
        (myconfig.programs.hyprland.enable or false) || (myconfig.programs.niri.enable or false);
    in
    lib.mkIf isWmEnabled {
      home.packages = [ universalLock ];

      services.hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "${universalLock}/bin/universal-lock";
            unlock_cmd = "";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };

          listener = [
            {
              # 🛠️ FIX: Use cfg to grab from default.nix OR fallback
              timeout = cfg.dimTimeout;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = cfg.lockTimeout;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = cfg.screenOffTimeout;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
