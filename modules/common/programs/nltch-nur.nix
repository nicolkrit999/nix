{ delib, lib, config, moduleSystem, ... }:
let
  cfg = config.myconfig.programs.nltchNur;
  shared = {
    environment.systemPackages = cfg.packages;
    nixpkgs.config.permittedInsecurePackages = cfg.permittedInsecurePackages;
  };
in
delib.module {
  name = "programs.nltchNur";

  options = delib.moduleOptions {
    enable = delib.boolOption false;
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    permittedInsecurePackages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };

  nixos.ifEnabled = shared;
  darwin.ifEnabled = shared;

  home.ifEnabled = lib.optionalAttrs (moduleSystem == "home") {
    home.packages = cfg.packages;
    nixpkgs.config.permittedInsecurePackages = cfg.permittedInsecurePackages;
  };
}
