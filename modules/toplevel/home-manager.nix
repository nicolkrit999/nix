{ delib, inputs, ... }:
delib.module {
  name = "system.home-manager";

  # 🌟 Use 'nixos.always' so the 'home-manager' option is at the system root
  nixos.always =
    { nixos, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.default ];

      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;

        # 🌟 THE FIX: Filter inputs to prevent the 'armv5tel' evaluation crash
        extraSpecialArgs = {
          inherit nixos;
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
