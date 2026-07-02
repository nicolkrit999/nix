{ delib, pkgs, ... }:
delib.module {
  name = "net";
  nixos.always = {
    networking.networkmanager.enable = true;
    environment.systemPackages = [ pkgs.networkmanagerapplet ];
  };
}
