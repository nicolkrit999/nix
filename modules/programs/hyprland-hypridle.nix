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
    dimTimeout = intOption 300;
    lockTimeout = intOption 330;
    screenOffTimeout = intOption 360;
  };

  home.always =
    {
      cfg,
      nixos,
      ...
    }:
    let
      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
      # 🌟 EXACT ORIGINAL SCRIPT
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

      # Original trigger condition
      isWmEnabled = (nixos.programs.hyprland.enable or false) || (nixos.programs.niri.enable or false);
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
              timeout = nixos.constants.dimTimeout;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = nixos.constants.lockTimeout;
              on-timeout = "loginctl lock-session";
            }
            {
              timeout = nixos.constants.screenOffTimeout;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }
          ];
        };
      };
    };
}
