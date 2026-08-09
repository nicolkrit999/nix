{ delib
, inputs
, pkgs
, ...
}:
let
  jetkvmTeardown = pkgs.writeShellScript "hyprland-jetkvm-teardown" ''
    set +e
    if [ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]; then
      sig=$(ls -1 "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -n1)
      [ -n "$sig" ] && export HYPRLAND_INSTANCE_SIGNATURE="$sig"
    fi
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "HDMI-A-1,disable"
    sleep 1
    exit 0
  '';
in
delib.host {
  name = "nixos-desktop";

  home = {
    home.activation.createDesktopDirs = inputs.home-manager.lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    '';

    programs.fish.interactiveShellInit = ''
      if test -r /run/secrets/hevy_api_key
        set -gx HEVY_API_KEY (cat /run/secrets/hevy_api_key)
      end
    '';

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
        RemainAfterExit = true;
        ExecStart = "${pkgs.coreutils}/bin/true";
        ExecStop = "${jetkvmTeardown}";
        TimeoutStopSec = "5s";
      };
    };
  };
}
