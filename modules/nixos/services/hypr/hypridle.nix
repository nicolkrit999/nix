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
        (myconfig.programs.hyprland.enable or false)
        || (myconfig.programs.niri.enable or false)
        || (myconfig.programs.mango.enable or false);

      # Skip idle actions while Nix is rebuilding
      busyGuard = "pgrep -f 'nix.build|nix.flake.check|nh.os|nixos-rebuild' > /dev/null && exit 0";

      mangoDpms = pkgs.writeShellApplication {
        name = "mango-dpms";
        runtimeInputs = [ pkgs.wlopm pkgs.gawk pkgs.coreutils ];
        text = ''
          rec="''${XDG_RUNTIME_DIR:-/tmp}/mango-dpms-''${WAYLAND_DISPLAY:-wayland-0}"
          case ''${1:-} in
            off)
              { cat "$rec" 2>/dev/null || true; wlopm | awk '$2 == "on" { print $1 }'; } | sort -u > "$rec.new"
              mv "$rec.new" "$rec"
              while read -r o; do wlopm --off "$o"; done < "$rec"
              ;;
            on)
              if [[ -s $rec ]]; then
                while read -r o; do wlopm --on "$o"; done < "$rec"
              fi
              rm -f "$rec"
              ;;
            *)
              exit 2
              ;;
          esac
        '';
      };

      dpmsOff = "if pgrep -x Hyprland > /dev/null; then hyprctl dispatch 'hl.dsp.dpms({ action = \"off\" })'; elif pgrep -x niri > /dev/null; then niri msg action power-off-monitors; elif pgrep -x mango > /dev/null; then ${lib.getExe mangoDpms} off; fi";
      dpmsOn = "if pgrep -x Hyprland > /dev/null; then hyprctl dispatch 'hl.dsp.dpms({ action = \"on\" })'; elif pgrep -x niri > /dev/null; then niri msg action power-on-monitors; elif pgrep -x mango > /dev/null; then ${lib.getExe mangoDpms} on; fi";
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
