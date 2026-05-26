{ delib
, inputs
, pkgs
, lib
, ...
}:
delib.module {
  name = "programs.caelestia";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      enableOnHyprland = boolOption false;
    };

  # Keep always so activation can depend on parent WM state.
  home.always =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      isX86 = pkgs.stdenv.hostPlatform.isx86_64;

      activeOnHyprland =
        isX86
        && cfg.enable
        && cfg.enableOnHyprland
        && (parent.hyprland.enable or false);

      # caelestia-shell only ships x86_64-linux outputs; guard the attr access to avoid eval failure on aarch64.
      caelestiaPkg =
        if isX86
        then inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
        else pkgs.emptyDirectory;

      caelestiaLogout = pkgs.writeShellScriptBin "caelestia-logout" ''
        # 1. If UWSM is running, use it (Most graceful)
        if command -v uwsm >/dev/null && pgrep -u $UID -x uwsm >/dev/null;
        then
            exec uwsm stop
        fi

        # 2. Fallback: If in Hyprland (without UWSM), exit Hyprland directly
        if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ];
        then
            exec hyprctl dispatch exit
        fi

        # 3. Fallback: If in Niri, exit Niri
        if [ "$XDG_CURRENT_DESKTOP" = "Niri" ];
        then
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
        if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ];
        then
            for i in {1..10};
            do
                export HYPRLAND_INSTANCE_SIGNATURE="$(${pkgs.hyprland}/bin/hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')"
                if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ];
                then break; fi
                if [ "$#" -eq 0 ];
                then sleep 0.5; else break; fi
            done
        fi

        echo "DEBUG: Caelestia connecting to Signature: $HYPRLAND_INSTANCE_SIGNATURE"

        # 2. Ensure socket & display
        export XDG_RUNTIME_DIR="/run/user/$(id -u)"
        export WAYLAND_DISPLAY="wayland-1"

        set -euo pipefail

        HM_PROFILE="/etc/profiles/per-user/${myconfig.constants.user}"

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
          if [ -d "$d" ];
          then
            if [ -z "$qmlPaths" ]; then qmlPaths="$d";
            else qmlPaths="$qmlPaths:$d"; fi
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
    in
    # caelestia-shell has no aarch64-linux outputs — skip the whole module on non-x86.
      # lib.optionalAttrs false returns {} without evaluating the body (unlike lib.mkIf which
      # the module system still validates even when the condition is false).
    lib.optionalAttrs isX86 {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      config = lib.mkIf activeOnHyprland {
        programs.caelestia = {
          enable = true;
          cli.enable = true;
          systemd.enable = false;
        };

        fonts.fontconfig.enable = true;

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
          pkgs.material-symbols
        ];

        wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
          "hyprctl systemd --export HYPRLAND_INSTANCE_SIGNATURE"
          "dbus-update-activation-environment --systemd XDG_SCREENSHOTS_DIR"
          "sh -lc 'XDG_SCREENSHOTS_DIR=${myconfig.constants.screenshots} caelestiaqs'"
        ];
      };
    };
}
