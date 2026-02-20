{ delib, pkgs, ... }:
delib.module {
  name = "system.net";
  myconfig.always = {
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ impala ];
  };
}
