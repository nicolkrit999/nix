{ delib, pkgs, ... }:
delib.module {
  name = "system.net";
  nixos.always = {
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ impala ];
  };
}
