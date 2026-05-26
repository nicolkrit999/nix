{ delib, lib, config, ... }:
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

  nixos.ifEnabled = {
    environment.systemPackages = config.myconfig.programs.nltchNur.packages;
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = config.myconfig.programs.nltchNur.permittedInsecurePackages;
    };
  };

  darwin.ifEnabled = {
    environment.systemPackages = config.myconfig.programs.nltchNur.packages;
    nixpkgs.config = {
      allowUnfree = true;
      permittedInsecurePackages = config.myconfig.programs.nltchNur.permittedInsecurePackages;
    };
  };
}
