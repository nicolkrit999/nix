{ delib, pkgs, ... }:
delib.module {
  name = "programs.statix";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      statix
    ];
  };
}
