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

  caelestiaQuickshell = pkgs.writeShellScriptBin "caelestia-quickshell" ''
    set -euo pipefail
    HM_PROFILE="${config.home.profileDirectory}"
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
        qmlPaths="$qmlPaths${"qmlPaths:+:"}$d"
      fi
    done
    export QML2_IMPORT_PATH="$qmlPaths''${QML2_IMPORT_PATH:+:$QML2_IMPORT_PATH}"
    export QT_QPA_PLATFORM="wayland"
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
      # Settings removed to allow GUI editing
    };

    home.packages = [
      caelestiaPkg
      caelestiaQuickshell
    ];

    home.activation.createCaelestiaConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      CONFIG_FILE="${config.xdg.configHome}/caelestia/shell.json"
      if [ ! -f "$CONFIG_FILE" ]; then
        echo "Creating default writable Caelestia config..."
        mkdir -p "$(dirname "$CONFIG_FILE")"
        cat <<EOF > "$CONFIG_FILE"
      {
        "background": { "enabled": false },
        "paths": { "wallpaperDir": "~/Pictures/Wallpapers" },
        "recorder": { "path": "~/Videos" },
        "services": { "useFahrenheit": ${
          if (vars.caelestiaUseFahrenheit or false) then "true" else "false"
        } }
      }
      EOF
      fi
    '';

    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "dbus-update-activation-environment --systemd XDG_SCREENSHOTS_DIR"
      "sh -lc 'sleep 1; XDG_SCREENSHOTS_DIR=${vars.screenshots} caelestia-quickshell'"
    ];
  };
}
