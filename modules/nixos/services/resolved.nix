{ delib, ... }:
delib.module {
  name = "services.resolved";
  options = delib.singleEnableOption false;

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
