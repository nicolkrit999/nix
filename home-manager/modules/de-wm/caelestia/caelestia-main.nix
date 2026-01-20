{ pkgs, lib, config, vars, inputs, ... }:
let
  caelestiaPkg =
    inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli;

  caelestiaLogout = pkgs.writeShellScriptBin "caelestia-logout" ''
    # 1. If UWSM is running, use it (Most graceful)
    if command -v uwsm >/dev/null && pgrep -u $UID -x uwsm >/dev/null; then
        exec uwsm stop
    fi

    # 2. Fallback: If in Hyprland (without UWSM), exit Hyprland directly
    if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
        exec hyprctl dispatch exit
    fi

    # 3. Fallback: If in Niri, exit Niri
    if [ "$XDG_CURRENT_DESKTOP" = "Niri" ]; then
        exec niri msg action quit
    fi

    # 4. Nuclear Option: Standard systemd logout
    exec loginctl terminate-user "$USER"
  '';

  caelestiaQS = pkgs.writeShellScriptBin "caelestiaqs" ''
    # -----------------------------------------------------------
    # 📝 CONFIG SETUP
    # -----------------------------------------------------------
    mkdir -p "$HOME/.config/caelestia"

    # -----------------------------------------------------------
    # 🔧 ENVIRONMENT & SIGNATURE FIX
    # -----------------------------------------------------------
    # 1. ALWAYS get a fresh signature using the absolute path to hyprctl
    export HYPRLAND_INSTANCE_SIGNATURE="$(${pkgs.hyprland}/bin/hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')"

    # Fallback: If empty (startup race condition), retry loop
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
        for i in {1..10}; do
            export HYPRLAND_INSTANCE_SIGNATURE="$(${pkgs.hyprland}/bin/hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')"
            if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then break; fi
            if [ "$#" -eq 0 ]; then sleep 0.5; else break; fi
        done
    fi

    echo "DEBUG: Caelestia connecting to Signature: $HYPRLAND_INSTANCE_SIGNATURE"

    # 2. Ensure socket & display
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export WAYLAND_DISPLAY="wayland-1"

    set -euo pipefail
    HM_PROFILE="${config.home.profileDirectory}"

    # 3. Unset conflicting vars
    unset QT_QUICK_CONTROLS_STYLE
    unset QT_QPA_PLATFORMTHEME
    unset QT_STYLE_OVERRIDE

    # 4. Construct QML paths
    qmlPaths=""
    for d in \
      "${caelestiaPkg}/lib/qt-6/qml" \
      "${caelestiaPkg}/lib/qt6/qml" \
      "${caelestiaPkg}/lib/qml" \
      "$HM_PROFILE/lib/qt-6/qml" \
      "$HM_PROFILE/lib/qt6/qml" \
      "$HM_PROFILE/lib/qml" \
      "$HOME/.config/quickshell"
    do
      if [ -d "$d" ]; then
        if [ -z "$qmlPaths" ]; then qmlPaths="$d"; else qmlPaths="$qmlPaths:$d"; fi
      fi
    done

    # Use shell expansion for the existing variable
    export QML2_IMPORT_PATH="$qmlPaths''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

    export QT_QPA_PLATFORM="wayland"
    export QT_QUICK_CONTROLS_STYLE="Basic"

    # -----------------------------------------------------------
    # 🚀 EXECUTION MODE
    # -----------------------------------------------------------
    if [ "$#" -gt 0 ]; then
       # COMMAND MODE: Forward arguments (e.g. 'ipc call...')
       exec "${caelestiaPkg}/bin/caelestia-shell" "$@"
    else
       # DAEMON MODE: Start the bar
       exec "${caelestiaPkg}/bin/caelestia-shell" -d
    fi
  '';
in {
  imports = [ inputs.caelestia-shell.homeManagerModules.default ];

  config =
    lib.mkIf ((vars.hyprland or false) && (vars.hyprlandCaelestia or false)) {

      programs.caelestia = {
        enable = true;
        cli.enable = true;
        systemd.enable = false;
      };

      home.packages = [
        caelestiaPkg
        caelestiaQS
        caelestiaLogout

        # Qt Dependencies
        pkgs.qt6.qt5compat
        pkgs.qt6.qtsvg
        pkgs.qt6.qtwayland
        pkgs.qt6.qtdeclarative
        pkgs.kdePackages.kirigami
        pkgs.nerd-fonts.caskaydia-cove
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.rubik
        (pkgs.runCommand "material-symbols-rounded" { } ''
          mkdir -p $out/share/fonts/truetype
          cp ${
            pkgs.fetchurl {
              url =
                "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf";
              sha256 = "sha256-1xnyL97ifjRLB+Rub6i1Cx/OPPywPUqE8D+vvwgS/CI=";
            }
          } $out/share/fonts/truetype/MaterialSymbolsRounded.ttf
        '')
      ];

      wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
        "hyprctl systemd --export HYPRLAND_INSTANCE_SIGNATURE"
        "dbus-update-activation-environment --systemd XDG_SCREENSHOTS_DIR"
        "sh -lc 'XDG_SCREENSHOTS_DIR=${vars.screenshots} caelestiaqs'"
      ];
    };
}
