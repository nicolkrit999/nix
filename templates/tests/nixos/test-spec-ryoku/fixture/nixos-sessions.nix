{ pkgs, ... }:
let
  session = name: pkgs.runCommand "fake-session-${name}" { passthru.providedSessions = [ name ]; } ''
    mkdir -p $out/share/wayland-sessions
    echo "[Desktop Entry]" > $out/share/wayland-sessions/${name}.desktop
  '';
in
{
  services.displayManager.sessionPackages = map session [ "ryoku-hyprland" "ryoku-niri" "ryoku-mango" ];
}
