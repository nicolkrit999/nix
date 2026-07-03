{ delib
, inputs
, pkgs
, ...
}:
let
  # Disable the JetKVM (HDMI-A-1) WHILE Hyprland (via UWSM) still owns the GPU,
  # before Hyprland itself exits during shutdown/reboot/logout.
  #
  # Why: the JetKVM is an always-powered HDMI-over-IP sink on HDMI-A-1 of the
  # 7900XTX. If the compositor releases DRM master with that stream still
  # active, amdgpu Display Core cannot blank that CRTC on the way down
  # ("REG_WAIT timeout ... optc3_lock" / "dcn20_wait_for_blank_complete failed
  # to blank crtc!"), retries for ~50s, and wedges the machine hard enough to
  # need a forced power-off. No kernel fix exists upstream as of 2026-07 (even
  # on 7.1.2-zen); tracked at jetkvm/kvm#1140. See also the HDMI-A-1 mirror
  # block in default.nix and the DP-3 comment in system.nix.
  #
  # This is a oneshot RemainAfterExit unit with a no-op ExecStart: all the
  # real work happens in ExecStop. Systemd stops "After=" units before the
  # unit they're ordered after, so binding After=graphical-session.target
  # guarantees this unit's ExecStop runs (and Hyprland/hyprctl are still
  # alive) before graphical-session.target - and therefore the UWSM-managed
  # Hyprland service - is torn down.
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
