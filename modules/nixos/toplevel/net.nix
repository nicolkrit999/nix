{ delib, pkgs, ... }:
delib.module {
  name = "net";
  nixos.always = {
    networking.networkmanager.enable = true;
    environment.systemPackages = with pkgs; [ impala ];
  };
}
