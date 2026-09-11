{ delib
, pkgs
, ...
}:
delib.module {
  name = "krit.services.desktop.ping-watchdog";
  options = delib.singleEnableOption false;

  nixos.ifEnabled =
    { myconfig, ... }:
    {
      # Household network-diagnostic watchdog: continuously pings a mix of
      # public (1.1.1.1, 9.9.9.9) and tailnet (100.72.14.7) targets, logging
      # reachability transitions - used to diagnose intermittent connectivity
      # issues. Declarative system service (not a home-manager/user service)
      # so it survives reboots without relying on `loginctl enable-linger`,
      # which would require adding /var/lib/systemd/linger to the
      # impermanence persistence allowlist for no real benefit.
      systemd.services.ping-watchdog = {
        description = "Continuous ping watchdog (1.1.1.1 / 9.9.9.9 / 100.72.14.7) for connectivity-outage diagnostics";
        after = [ "network-online.target" "tailscaled.service" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        # System services get a minimal default PATH that doesn't include
        # /run/current-system/sw/bin, so the script's `#!/usr/bin/env bash`
        # shebang fails to resolve bash, and the script's own `ping` calls
        # would fail the same way once that's fixed.
        path = [ pkgs.bash pkgs.iputils ];

        serviceConfig = {
          Type = "simple";
          User = myconfig.constants.user;
          ExecStart = "/home/${myconfig.constants.user}/bin/ping-watchdog.sh";
          Restart = "always";
          RestartSec = "5s";
        };
      };
    };
}
