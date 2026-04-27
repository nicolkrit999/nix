{ delib, inputs, ... }:
delib.module {
  name = "home-manager";

  nixos.always =
    { myconfig, ... }:
    {

      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;

        extraSpecialArgs = {
          inherit myconfig;
          inputs = {
            inherit (inputs)
              nixpkgs
              home-manager
              catppuccin
              plasma-manager
              stylix
              ;
          };
        };

        sharedModules = [
          inputs.catppuccin.homeModules.catppuccin
          inputs.plasma-manager.homeModules.plasma-manager
        ];
      };
    };
}
