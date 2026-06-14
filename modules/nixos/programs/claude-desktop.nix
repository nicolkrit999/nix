{ delib, inputs, pkgs, ... }:
let
  system = pkgs.stdenv.hostPlatform.system;
in
delib.module {
  name = "programs.claude-desktop";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = {
    environment.systemPackages = [ inputs.claude-desktop.packages.${system}.claude-desktop-fhs ];
  };
}
