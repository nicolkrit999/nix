{ delib
, inputs
, pkgs
, lib
, ...
}:

delib.module {
  name = "programs.noctalia";
  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      enableOnHyprland = boolOption false;
      enableOnNiri = boolOption false;
    };

  # Keep always so the cross-shell assertion fires regardless of enable state.
  home.always =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      activeOnHyprland =
        cfg.enable
        && cfg.enableOnHyprland
        && (parent.hyprland.enable or false);

      activeOnNiri =
        cfg.enable
        && cfg.enableOnNiri
        && (parent.niri.enable or false);

      active = activeOnHyprland || activeOnNiri;

      caelestiaActiveOnHyprland =
        (parent.caelestia.enable or false)
        && (parent.caelestia.enableOnHyprland or false)
        && (parent.hyprland.enable or false);

      noctaliaPkg = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;

      extraQmlPackages = [
        pkgs.kdePackages.kirigami
        pkgs.kdePackages.qqc2-desktop-style
        pkgs.kdePackages.breeze-icons
      ];

      startNoctalia = pkgs.writeShellScriptBin "start-noctalia" ''
        # -----------------------------------------------------------
        # 📝 CONFIG SETUP (Manual Mode)
        # -----------------------------------------------------------
        USER_CONFIG_DIR="$HOME/.config/noctalia"
        USER_CONFIG_FILE="$USER_CONFIG_DIR/config.json"

        # Just ensure the directory exists so the app can write to it
        mkdir -p "$USER_CONFIG_DIR"

        export NOCTALIA_SETTINGS_FILE="$USER_CONFIG_FILE"

        # -----------------------------------------------------------
        # 🔧 ENVIRONMENT FIXES
        # -----------------------------------------------------------
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ] && [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ] && command -v hyprctl &> /dev/null; then
            for i in {1..10}; do
                DETECTED_SIG=$(hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')
                if [ -n "$DETECTED_SIG" ]; then
                    export HYPRLAND_INSTANCE_SIGNATURE="$DETECTED_SIG"
                    break
                fi
                sleep 0.5
            done
        fi

        export QML2_IMPORT_PATH=""
        for pkg in ${builtins.toString extraQmlPackages}; do
          if [ -d "$pkg/lib/qt-6/qml" ]; then
            export QML2_IMPORT_PATH="$pkg/lib/qt-6/qml:$QML2_IMPORT_PATH"
          fi
        done

        # -----------------------------------------------------------
        # 🚀 LAUNCH
        # -----------------------------------------------------------
        ${noctaliaPkg}/bin/noctalia-shell &
        PID=$!

        # Sync weather location from Nix variables on boot
        sleep 5
        ${noctaliaPkg}/bin/noctalia-shell ipc call location set "${myconfig.constants.weather or "London"}"

        wait $PID
      '';
    in
    lib.mkMerge [
      {
        assertions = [
          {
            assertion = !(activeOnHyprland && caelestiaActiveOnHyprland);
            message = "Both caelestia and noctalia are active on Hyprland — only one shell may be active per WM.";
          }
        ];
      }
      (lib.mkIf active {
        home.packages = [
          noctaliaPkg
          startNoctalia

          # Runtime dependencies
          pkgs.wlsunset
          pkgs.cava
          pkgs.evolution-data-server
        ]
        ++ extraQmlPackages;

        # Hyprland Autostart
        wayland.windowManager.hyprland.settings.exec-once = lib.optionals activeOnHyprland [
          "start-noctalia"
        ];

        # Niri Autostart
        programs.niri.settings.spawn-at-startup = lib.optionals activeOnNiri [
          { command = [ "start-noctalia" ]; }
        ];
      })
    ];
}
