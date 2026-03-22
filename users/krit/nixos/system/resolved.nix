{ delib, ... }:
delib.module {
  name = "krit.system.resolved";
  options.krit.system.resolved = with delib; {
    enable = boolOption false;
  };

  nixos.ifEnabled = {
    services.resolved = {
      enable = true;
      dnssec = "false";
      domains = [ "~." ];
      fallbackDns = [
        "9.9.9.9"
        "149.112.112.112"
      ];
      dnsovertls = "opportunistic";
    };
  };
}
