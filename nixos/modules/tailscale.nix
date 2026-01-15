{
  lib,
  config,
  vars,
  ...
}:
{
  config = lib.mkIf vars.tailscale {
    services.tailscale.enable = true;

    networking.firewall = {
      allowedUDPPorts = [ 41641 ]; # Default Tailscale port
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # Strict reverse path filtering breaks VPNs
    };
  };
}
