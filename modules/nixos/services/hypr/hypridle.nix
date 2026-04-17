{ delib
, inputs
, pkgs
, lib

, ...
}:
delib.module {
  name = "services.hypridle";

  options = with delib; moduleOptions {
    enable = boolOption true;
    dimTimeout = intOption 300;
    lockTimeout = intOption 330;
    screenOffTimeout = intOption 360;
  };


  home.ifEnabled =
    { cfg
    , myconfig
    , ...
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

      isWmEnabled =
        (myconfig.programs.hyprland.enable or false) || (myconfig.programs.niri.enable or false);

      # Skip idle actions while Nix is rebuilding
      busyGuard = "pgrep -f 'nix.build|nix.flake.check|nh.os|nixos-rebuild' > /dev/null && exit 0";

      # Compositor-aware DPMS commands (works on both Hyprland and niri)
      dpmsOff = "if pgrep -x Hyprland > /dev/null; then hyprctl dispatch dpms off; elif pgrep -x niri > /dev/null; then niri msg action power-off-monitors; fi";
      dpmsOn = "if pgrep -x Hyprland > /dev/null; then hyprctl dispatch dpms on; elif pgrep -x niri > /dev/null; then niri msg action power-on-monitors; fi";
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
            after_sleep_cmd = dpmsOn;
          };

          listener = [
            {
              timeout = cfg.dimTimeout;
              on-timeout = "${busyGuard}; brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
            }
            {
              timeout = cfg.lockTimeout;
              on-timeout = "${busyGuard}; loginctl lock-session";
            }
            {
              timeout = cfg.screenOffTimeout;
              on-timeout = "${busyGuard}; ${dpmsOff}";
              on-resume = dpmsOn;
            }
          ];
        };
      };
    };
}
