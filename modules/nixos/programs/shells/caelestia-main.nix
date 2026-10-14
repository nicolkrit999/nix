{ delib
, inputs
, pkgs
, lib
, ...
}:
let
  activeOnHyprland = cfg: parent:
    pkgs.stdenv.hostPlatform.isx86_64
    && cfg.enable
    && cfg.enableOnHyprland
    && parent.hyprland.enable;
in
delib.module {
  name = "programs.caelestia";

  options =
    with delib;
    moduleOptions {
      enable = boolOption false;
      enableOnHyprland = boolOption false;
    };

  # always: the HM `imports` must live in an always block; activation is gated per option below.
  home.always =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      active = activeOnHyprland cfg parent;

      # The flake input is only evaluated on x86_64; other arches get an empty stand-in.
      caelestiaPkg =
        if pkgs.stdenv.hostPlatform.isx86_64
        then inputs.caelestia-shell.packages.${pkgs.stdenv.hostPlatform.system}.with-cli
        else pkgs.emptyDirectory;

      caelestiaQS = pkgs.writeShellScriptBin "caelestiaqs" ''
        mkdir -p "$HOME/.config/caelestia"

        if [ -z "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
          for _ in {1..10}; do
            HYPRLAND_INSTANCE_SIGNATURE="$(${pkgs.hyprland}/bin/hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')"
            if [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]; then break; fi
            if [ "$#" -eq 0 ]; then sleep 0.5; else break; fi
          done
          export HYPRLAND_INSTANCE_SIGNATURE
        fi

        : "''${XDG_RUNTIME_DIR:=/run/user/$(id -u)}"
        : "''${WAYLAND_DISPLAY:=wayland-1}"
        export XDG_RUNTIME_DIR WAYLAND_DISPLAY

        set -euo pipefail

        HM_PROFILE="/etc/profiles/per-user/${myconfig.constants.user}"

        unset QT_QPA_PLATFORMTHEME
        unset QT_STYLE_OVERRIDE

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

        export QML2_IMPORT_PATH="$qmlPaths''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"

        export QT_QPA_PLATFORM="wayland"
        export QT_QUICK_CONTROLS_STYLE="Basic"

        if [ "$#" -gt 0 ]; then
          exec "${caelestiaPkg}/bin/caelestia-shell" "$@"
        else
          exec "${caelestiaPkg}/bin/caelestia-shell" -d
        fi
      '';
    in
    {
      imports = [ inputs.caelestia-shell.homeManagerModules.default ];

      programs.caelestia = lib.mkIf active {
        enable = true;
        package = caelestiaPkg;
        cli.enable = true;
        systemd.enable = false;
      };

      fonts.fontconfig.enable = lib.mkIf active true;

      home.packages = lib.mkIf active [
        caelestiaQS

        # Qt Dependencies
        pkgs.qt6.qt5compat
        pkgs.qt6.qtsvg
        pkgs.qt6.qtwayland
        pkgs.qt6.qtdeclarative

        pkgs.kdePackages.kirigami
        pkgs.nerd-fonts.jetbrains-mono
        pkgs.material-symbols
      ];
    };

  nixos.always =
    { cfg
    , parent
    , myconfig
    , ...
    }:
    let
      active = activeOnHyprland cfg parent;
    in
    {
      programs.gpu-screen-recorder.enable = lib.mkIf active true;

      myconfig.programs.hyprland.shellExecOnce = lib.mkIf active [
        "sh -lc 'XDG_SCREENSHOTS_DIR=${myconfig.constants.screenshots} caelestiaqs'"
      ];
    };
}
