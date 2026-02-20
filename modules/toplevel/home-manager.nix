{ delib, inputs, ... }:
delib.module {
  name = "system.home-manager";

  myconfig.always =
    { myconfig, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.default ];

      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs myconfig; };
        sharedModules = [
          inputs.catppuccin.homeModules.catppuccin
          inputs.plasma-manager.homeModules.plasma-manager
        ];
      };
    };
}
