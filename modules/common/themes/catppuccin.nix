{ delib, inputs, moduleSystem, lib, ... }:
delib.module {
  name = "themes.catppuccin";

  nixos.always = { ... }: {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];

    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  darwin.always = { ... }: {
    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  # Critical for CI: ensures catppuccin options exist during `nix flake check`
  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };
}
