{ delib, ... }:
delib.module {
  name = "services.tailscale";
  options.services.tailscale = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    services.tailscale.enable = true;

    networking.firewall = {
      allowedUDPPorts = [ 41641 ];
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # Strict reverse path filtering breaks VPNs
    };
  };
}
