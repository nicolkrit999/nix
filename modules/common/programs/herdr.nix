{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  herdr = inputs.herdr.packages.${system}.default;
in
delib.module {
  # herdr - terminal agent-multiplexer
  name = "programs.herdr";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ herdr ];
  };

  darwin.ifEnabled = {
    environment.systemPackages = [ herdr ];
  };
}
