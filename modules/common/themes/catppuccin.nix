{ delib, inputs, moduleSystem, lib, ... }:
delib.module {
  name = "themes.catppuccin";

  # NixOS system-level catppuccin
  nixos.always = { ... }: {
    imports = [ inputs.catppuccin.nixosModules.catppuccin ];

    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  # Darwin system-level: inject catppuccin into home-manager via sharedModules
  darwin.always = { ... }: {
    home-manager.sharedModules = [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };

  # Home-manager catppuccin for standalone homeConfigurations (moduleSystem == "home")
  # Only import for standalone builds - integrated builds use sharedModules above
  # Critical for CI: ensures catppuccin options exist during `nix flake check`
  home.always = { ... }: {
    imports = lib.optionals (moduleSystem == "home") [
      inputs.catppuccin.homeModules.catppuccin
    ];
  };
}
