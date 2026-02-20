{ delib, inputs, ... }:
delib.module {
  name = "system.home-manager";

  nixos.always =
    { myconfig, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.default ];

      # home-manager.nix
      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;

        # 🌟 THE FIX: Pass only the inputs you actually need for Home Manager.
        # This prevents the 'armv5tel' crash from the shell flakes.
        extraSpecialArgs = {
          inherit myconfig;
          inputs = {
            inherit (inputs)
              nixpkgs
              home-manager
              catppuccin
              plasma-manager
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
