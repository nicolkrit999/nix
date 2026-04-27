{ delib
, pkgs
, inputs
, lib
, moduleSystem
, ...
}:
delib.module {
  name = "programs.niri";
  options = delib.singleEnableOption false;

  nixos.always = { ... }: {
    imports = [
      inputs.niri.nixosModules.niri
    ];
    programs.niri.package = pkgs.niri;
  };

  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.niri.homeModules.niri
    ];
  };

  nixos.ifEnabled = {
    programs.niri = {
      enable = true;
    };
  };
}
