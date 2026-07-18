{ delib, pkgs, ... }:
delib.module {
  name = "services.tailscale";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.tailscale.enable = true;

    networking.firewall = {
      allowedUDPPorts = [ 41641 ];
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # Strict reverse path filtering breaks VPNs
    };

    systemd.services.tailscale-autoconnect = {
      description = "Retry `tailscale up` until network is actually ready";
      after = [
        "network-online.target"
        "NetworkManager-wait-online.service"
        "tailscaled.service"
      ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };

      # Bounded retry loop: up to 20 attempts, 15s apart (~5 minutes total)
      # before giving up and leaving it to be retried on the next boot / manually.
      script = ''
        for i in $(seq 1 20); do
          if ${pkgs.tailscale}/bin/tailscale up; then
            exit 0
          fi
          sleep 15
        done
        echo "tailscale-autoconnect: giving up after repeated failures" >&2
        exit 1
      '';
    };
  };

  darwin.ifEnabled = {
    services.tailscale.enable = true;
  };
}
