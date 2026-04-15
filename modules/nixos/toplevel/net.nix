{ delib, ... }:
delib.module {
  name = "net";
  nixos.always = {
    networking.networkmanager.enable = true;
  };
}


