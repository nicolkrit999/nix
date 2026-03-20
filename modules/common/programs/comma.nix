{ delib, pkgs, ... }:
delib.module {
  name = "programs.comma";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = with pkgs; [
      comma
    ];
  };
}
