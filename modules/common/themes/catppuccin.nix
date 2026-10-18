{ delib, inputs, moduleSystem, lib, ... }:
delib.module {
  name = "themes.catppuccin";

  nixos.always = { ... }: {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];

    catppuccin = {
      enable = true;
      autoEnable = false;
    };

    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  darwin.always = _: {
    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  # Standalone home builds have no host to add the HM module via sharedModules; import it here.
  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.catppuccin.homeModules.catppuccin
    ];

    catppuccin = {
      enable = true;
      autoEnable = false;
    };
  };
}
