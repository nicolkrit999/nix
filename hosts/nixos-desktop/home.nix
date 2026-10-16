{ delib
, pkgs
, ...
}:
let
  isHyprlandSession = pkgs.writeShellScript "is-hyprland-session" ''
    case ":$XDG_CURRENT_DESKTOP:" in
      *:Hyprland:*) exit 0 ;;
    esac
    [ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]
  '';

  jetkvmTeardown = pkgs.writeShellScript "hyprland-jetkvm-teardown" ''
    set +e
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      for dir in "$XDG_RUNTIME_DIR"/hypr/*/; do
        [ -d "$dir" ] || continue
        dir=''${dir%/}
        export HYPRLAND_INSTANCE_SIGNATURE=''${dir##*/}
        break
      done
    fi
    ${pkgs.hyprland}/bin/hyprctl eval 'hl.monitor({ output = "HDMI-A-1", disabled = true })'
    sleep 1
    exit 0
  '';
in
delib.host {
  name = "nixos-desktop";

  home = {
    systemd.user.services.hyprland-jetkvm-teardown = {
      Unit = {
        Description = "Disable JetKVM (HDMI-A-1) before Hyprland exits to avoid amdgpu blank-crtc wedge (jetkvm/kvm#1140)";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecCondition = "${isHyprlandSession}";
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = "${jetkvmTeardown}";
        TimeoutStopSec = "5s";
      };
    };
  };
}
