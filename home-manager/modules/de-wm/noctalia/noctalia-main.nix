{
  pkgs,
  lib,
  config,
  vars,
  inputs,
  ...
}:
let
  # Detect which shell hyprland has to avoid conflicts
  enableHyprland =
    (vars.hyprland or false) && (vars.hyprlandNoctalia or false) && !(vars.hyprlandCaelestia or false);

  enableNiri = (vars.niri or false) && (vars.niriNoctalia or false);

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

    # Optional: Sync weather location from Nix variables on boot
    sleep 5
    ${noctaliaPkg}/bin/noctalia-shell ipc call location set "${vars.weather or "London"}"

    wait $PID
  '';
in
{

  config =
    lib.mkIf ((enableHyprland || enableNiri) && pkgs.stdenv.hostPlatform.system == "x86_64-linux")
      {

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
        wayland.windowManager.hyprland.settings.exec-once = lib.optionals enableHyprland [
          "start-noctalia"
        ];

        # Niri Autostart
        programs.niri.settings.spawn-at-startup = lib.optionals enableNiri [
          { command = [ "start-noctalia" ]; }
        ];
      };
}
