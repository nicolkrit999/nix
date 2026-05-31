{ delib, ... }:
delib.module {
  name = "services.resolved";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    services.resolved = {
      enable = true;
      settings.Resolve = {
        DNSSEC = "false";
        Domains = "~.";
        FallbackDNS = "9.9.9.9 149.112.112.112";
        DNSOverTLS = "opportunistic";
      };
    };
  };
}
