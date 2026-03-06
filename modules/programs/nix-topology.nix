{ delib, inputs, ... }:
delib.module {
  name = "services.nix-topology";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };
}
