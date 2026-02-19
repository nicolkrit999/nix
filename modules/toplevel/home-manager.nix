{ delib, inputs, ... }:
delib.module {
  name = "system.home-manager";
  nixos.always =
    { ... }:
    {
      imports = [ inputs.home-manager.nixosModules.default ];
    };
}
