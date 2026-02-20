{ delib, inputs, ... }:
delib.module {
  name = "home-manager";

  # 🌟 Use 'nixos.always' so the 'home-manager' option is at the system root
  nixos.always =
    { cfg, myconfig, ... }:
    {

      home-manager = {
        useGlobalPkgs = false;
        useUserPackages = true;

        # 🌟 THE FIX: Filter inputs to prevent the 'armv5tel' evaluation crash
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
