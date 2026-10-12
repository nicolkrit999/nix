{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  overlays = [ inputs.codex-cli-nix.overlays.default ];
  shared = {
    nixpkgs.overlays = overlays;
    environment.systemPackages = [ pkgs.codex ];
  };
in
delib.module {
  name = "programs.codex";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = lib.optionalAttrs (moduleSystem == "home") {
    nixpkgs.overlays = overlays;
    home.packages = [ pkgs.codex ];
  };
}
