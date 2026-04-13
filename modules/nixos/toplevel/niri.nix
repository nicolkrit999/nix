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

  # NixOS: import niri nixosModule (includes home-manager integration via sharedModules)
  nixos.always = { ... }: {
    imports = [
      inputs.niri.nixosModules.niri
    ];
    programs.niri.package = pkgs.niri;
  };

  # Standalone homeConfigurations: import niri home module directly
  # Only for moduleSystem == "home" to avoid duplication with nixos.always above
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
