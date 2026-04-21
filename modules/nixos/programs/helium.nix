{ delib, inputs, pkgs, ... }:
delib.module {
  name = "programs.helium";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
