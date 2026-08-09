{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
  codex = inputs.codex-cli-nix.packages.${system}.default;
in
delib.module {
  name = "programs.codex";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ codex ];
  };

  darwin.ifEnabled = {
    environment.systemPackages = [ codex ];
  };
}
