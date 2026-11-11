{ delib, inputs, pkgs, lib, moduleSystem, ... }:
let
  herdrPkgs = inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system} or { };
  herdrPackages = lib.filter (lib.meta.availableOn pkgs.stdenv.hostPlatform)
    (lib.attrVals (lib.filter (n: herdrPkgs ? ${n}) [ "herdr" "herdr-core" "herdr-tui" ]) herdrPkgs);
  shared = {
    environment.systemPackages = herdrPackages;
  };
in
delib.module {
  name = "programs.herdr";
  options = delib.singleEnableOption false;

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = {
    home.packages = lib.optionals (moduleSystem == "home") herdrPackages;
  };
}
