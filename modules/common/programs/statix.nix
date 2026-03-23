{ delib, pkgs, ... }:
delib.module {
  name = "programs.statix";
  options = delib.singleEnableOption false;

  home.ifEnabled = {
    home.packages = with pkgs; [
      statix
    ];
  };
}
