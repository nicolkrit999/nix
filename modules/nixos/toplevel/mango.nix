{ delib
, inputs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "programs.mango";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [
      inputs.mango.nixosModules.mango
    ];
    home-manager.sharedModules = [
      inputs.mango.hmModules.mango
    ];
  };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.mango.hmModules.mango
    ];
  };

  nixos.ifEnabled = {
    programs.mango = {
      enable = true;
    };
  };
}
