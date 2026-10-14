{ delib
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
      noctalia = myconfig.programs.noctalia or { };
      caelestia = myconfig.programs.caelestia or { };
      noctaliaOn = wm: (noctalia."enableOn${wm}" or false) && (myconfig.programs.${lib.toLower wm}.enable or false);
      noctaliaActive =
        pkgs.stdenv.hostPlatform.isx86_64
        && (noctalia.enable or false)
        && (noctaliaOn "Hyprland" || noctaliaOn "Niri" || noctaliaOn "Mango");

      caelestiaActive =
        pkgs.stdenv.hostPlatform.isx86_64
        && (caelestia.enable or false)
        && (caelestia.enableOnHyprland or false)
        && (myconfig.programs.hyprland.enable or false);

      universalLock = pkgs.writeShellScriptBin "universal-lock" (lib.optionalString noctaliaActive ''
        if ${lib.getExe pkgs.noctalia} msg session lock > /dev/null 2>&1; then
           exit 0
        fi
      '' + lib.optionalString caelestiaActive ''
        if pgrep -f caelestia-shell > /dev/null && caelestiaqs ipc call lock lock > /dev/null 2>&1; then
           exit 0
        fi
      '' + ''
        if command -v hyprlock > /dev/null; then
           pidof hyprlock || hyprlock
           exit 0
        fi
      '');

      wmEnabled = wm: myconfig.programs.${wm}.enable or false;
      isWmEnabled = wmEnabled "hyprland" || wmEnabled "niri" || wmEnabled "mango";
      wmTargets =
        lib.optional (wmEnabled "hyprland") "hyprland-session.target"
        ++ lib.optional (wmEnabled "niri") "niri.service"
        ++ lib.optional (wmEnabled "mango") "mango-session.target";

      # A script file, so pgrep -f cannot match the pattern in a parent `sh -c` command line.
      nixBusy = pkgs.writeShellScript "nix-busy" ''
        pgrep -f 'nix.build|nix.flake.check|nh.os|nixos-rebuild' > /dev/null
      '';
      busyGuard = "${nixBusy} && exit 0";

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

      dpms = state: "if pgrep -x Hyprland > /dev/null; then hyprctl dispatch 'hl.dsp.dpms({ action = \"${state}\" })'; elif pgrep -x niri > /dev/null; then niri msg action power-${state}-monitors; elif pgrep -x mango > /dev/null; then ${lib.getExe mangoDpms} ${state}; fi";
      dpmsOff = dpms "off";
      dpmsOn = dpms "on";
    in
    lib.mkIf isWmEnabled {
      home.packages = [ universalLock ];

      systemd.user.services.hypridle = {
        Unit.PartOf = lib.mkForce wmTargets;
        Unit.After = lib.mkForce wmTargets;
        Install.WantedBy = lib.mkForce wmTargets;
      };

      services.hypridle = {
        enable = true;

        settings = {
          general = {
            lock_cmd = "${universalLock}/bin/universal-lock";
            before_sleep_cmd = "loginctl lock-session";
            after_sleep_cmd = dpmsOn;
          };

          listener = [
            {
              timeout = cfg.dimTimeout;
              on-timeout = "${busyGuard}; brightnessctl -c backlight -s set 10";
              on-resume = "brightnessctl -c backlight -r";
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
