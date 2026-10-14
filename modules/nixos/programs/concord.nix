{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  concord = inputs.concord.packages.${system}.default;
in
delib.module {
  name = "programs.concord";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ concord ];
  };
}
