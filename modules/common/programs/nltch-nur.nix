{ delib, lib, config, ... }:
let
  sharedIfEnabled = {
    environment.systemPackages = config.myconfig.programs.nltchNur.packages;
  };
  sharedAlways = {
    nixpkgs.config = {
      permittedInsecurePackages = config.myconfig.programs.nltchNur.permittedInsecurePackages;
    };
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

  nixos.ifEnabled = sharedIfEnabled;
  nixos.always = sharedAlways;

  darwin.ifEnabled = sharedIfEnabled;
  darwin.always = sharedAlways;
}
