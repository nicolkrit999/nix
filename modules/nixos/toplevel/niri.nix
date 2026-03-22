{ delib
, pkgs
, inputs
, ...
}:
delib.module {
  name = "programs.niri";
  options = delib.singleEnableOption false;

  # Import niri nixosModule (includes home-manager integration)
  nixos.always = { ... }: {
    imports = [
      inputs.niri.nixosModules.niri
    ];
  };

  nixos.ifEnabled = {
    programs.niri = {
      enable = true;
      package = pkgs.niri;
    };
  };
}
