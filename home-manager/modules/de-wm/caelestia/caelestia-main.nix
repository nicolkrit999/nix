{
  pkgs,
  lib,
  config,
  vars,
  inputs,
  ...
}:
let
  caelestiaPkg = inputs.caelestia-shell.packages.${pkgs.system}.with-cli;

  caelestiaConfig = import ./caelestia-config.nix { inherit vars; };

  caelestiaQS = pkgs.writeShellScriptBin "caelestiaqs" ''
    # 1. Wait for Hyprland to finish initialization
    sleep 2

    # 2. Get the signature
    export HYPRLAND_INSTANCE_SIGNATURE=$(hyprctl instances | head -n 1 | cut -d " " -f 2 | tr -d ':')

    # 3. Ensure the shell can find the IPC socket
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"
    export WAYLAND_DISPLAY="wayland-1"

    set -euo pipefail
    HM_PROFILE="${config.home.profileDirectory}"

    # ... keep your existing unset logic ...
    unset QT_QUICK_CONTROLS_STYLE
    unset QT_QPA_PLATFORMTHEME
    unset QT_STYLE_OVERRIDE

    # ... keep your existing qmlPaths loop ...
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

    export QML2_IMPORT_PATH="$qmlPaths''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    export QT_QPA_PLATFORM="wayland"
    export QT_QUICK_CONTROLS_STYLE="Basic"

    exec "${caelestiaPkg}/bin/caelestia-shell" -d
  '';

in
{
  imports = [
    inputs.caelestia-shell.homeManagerModules.default
  ];

  config = lib.mkIf ((vars.hyprland or false) && (vars.caelestia or false)) {
    programs.caelestia = {
      enable = true;
      cli.enable = true;
      systemd.enable = false;
    };

    xdg.configFile."caelestia/shell.json".text = builtins.toJSON caelestiaConfig;

    home.packages = [
      caelestiaPkg
      caelestiaQS

      pkgs.qt6.qt5compat
      pkgs.qt6.qtsvg
      pkgs.qt6.qtwayland
      pkgs.qt6.qtdeclarative

      pkgs.nerd-fonts.caskaydia-cove
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.rubik

      pkgs.mpv

      (pkgs.runCommand "material-symbols-rounded" { } ''
        mkdir -p $out/share/fonts/truetype
        cp ${
          pkgs.fetchurl {
            url = "https://github.com/google/material-design-icons/raw/master/variablefont/MaterialSymbolsRounded%5BFILL%2CGRAD%2Copsz%2Cwght%5D.ttf";
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
