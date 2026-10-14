{ delib
, pkgs
, lib
, ...
}:
let
  activeOn = cfg: parent: wm:
    pkgs.stdenv.hostPlatform.isx86_64
    && cfg.enable
    && cfg."enableOn${wm}"
    && parent.${lib.toLower wm}.enable;
in
delib.module {
  name = "programs.noctalia";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      enableOnHyprland = boolOption false;
      enableOnNiri = boolOption false;
      enableOnMango = boolOption false;
    };

  home.always =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      activeOnHyprland = activeOn cfg parent "Hyprland";
      activeOnNiri = activeOn cfg parent "Niri";
      activeOnMango = activeOn cfg parent "Mango";
      active = activeOnHyprland || activeOnNiri || activeOnMango;

      caelestiaActiveOnHyprland =
        parent.caelestia.enable
        && parent.caelestia.enableOnHyprland
        && parent.hyprland.enable;

      noctaliaPkg = pkgs.noctalia;

      startNoctalia = pkgs.writeShellScriptBin "start-noctalia" ''
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl > /dev/null; then
          for _ in {1..10}; do
            DETECTED_SIG=$(hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')
            if [ -n "$DETECTED_SIG" ]; then
              export HYPRLAND_INSTANCE_SIGNATURE="$DETECTED_SIG"
              break
            fi
            sleep 0.5
          done
        fi

        exec ${lib.getExe noctaliaPkg}
      '';
    in
    {
      assertions = [
        {
          assertion = !(activeOnHyprland && caelestiaActiveOnHyprland);
          message = "Both caelestia and noctalia are active on Hyprland - only one shell may be active per WM.";
        }
      ];

      programs.noctalia = lib.mkIf active {
        enable = true;
        package = noctaliaPkg;
        settings = {
          location.address = myconfig.constants.weather;
          weather.enabled = true;
        };
      };

      home.packages = lib.mkIf active [ startNoctalia ];

      programs.niri.settings = lib.mkIf activeOnNiri {
        spawn-at-startup = [
          { command = [ "start-noctalia" ]; }
        ];
      };

      wayland.windowManager.mango.settings.exec_once = lib.mkIf activeOnMango (lib.mkAfter [
        "start-noctalia"
      ]);
    };

  nixos.always =
    { cfg
    , parent
    , ...
    }:
    let
      activeOnHyprland = activeOn cfg parent "Hyprland";
      active = activeOnHyprland || activeOn cfg parent "Niri" || activeOn cfg parent "Mango";
    in
    {
      programs.gpu-screen-recorder.enable = lib.mkIf active true;

      myconfig.programs.hyprland.shellExecOnce = lib.mkIf activeOnHyprland [
        "start-noctalia"
      ];
    };
}
