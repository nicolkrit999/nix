{
  lib,
  config,
  vars,
  ...
}:
{
  config = lib.mkIf vars.tailscale {
    # 1. Enable the Service
    services.tailscale.enable = true;

    # 2. Firewall Logic (Required for features like Taildrop)
    networking.firewall = {
      allowedUDPPorts = [ 41641 ]; # Default Tailscale port
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose"; # Strict reverse path filtering breaks VPNs
    };
  };
}
