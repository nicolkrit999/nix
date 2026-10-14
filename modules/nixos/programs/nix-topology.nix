{ delib, inputs, ... }:
delib.module {
  name = "programs.nix-topology";

  nixos.always = {
    imports = [ inputs.nix-topology.nixosModules.default ];
  };
}
