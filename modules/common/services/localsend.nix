{ delib, ... }:
delib.module {
  name = "services.localsend";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    networking.firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
  };
}
