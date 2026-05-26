{ delib, inputs, ... }:
delib.module {
  name = "programs.nix-topology";
  options = delib.singleEnableOption false;

  nixos.always = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };
}
