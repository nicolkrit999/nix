{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  herdr = inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  shared = {
    environment.systemPackages = [ herdr ];
  };
in
delib.module {
  name = "programs.herdr";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = {
    home.packages = lib.optionals (moduleSystem == "home") [ herdr ];
  };
}
