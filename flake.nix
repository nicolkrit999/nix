{
  description = "NixOS configuration with multiple hosts, denix, cachix, sops";

  outputs =
    { denix, nixpkgs, ... }@inputs:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      mkConfigurations =
        moduleSystem:
        denix.lib.configurations {
          inherit moduleSystem;
          homeManagerUser = "krit";

          extensions = with denix.lib.extensions; [
            args
            (base.withConfig {
              args.enable = true;
              rices.enable = false;
            })
          ];

          paths = [
            ./hosts
            ./modules
            ./packages
            ./users
          ];

          exclude = [
            ./users/krit/dev-environments
            ./users/krit/modules/programs/gui-programs/librewolf/profiles

            # TODO: see for hardware configuration if it support a wildcard to match any "hardware-configuration.nix"
            ./hosts/nixos-desktop/hardware-configuration.nix
            ./hosts/nixos-laptop/hardware-configuration.nix
            ./hosts/template-host-minimal/hardware-configuration.nix
            ./hosts/template-host-full/hardware-configuration.nix

            # TODO: see for disko configuration if it support a wildcard to match any "disko-config.nix"
            ./hosts/template-host-minimal/disko-config.nix
            ./hosts/template-host-full/disko-config.nix

          ];

          specialArgs = { inherit inputs moduleSystem; };
        };
    in
    {
      nixosConfigurations = mkConfigurations "nixos";
      homeConfigurations = mkConfigurations "home";
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Needed to get firefox addons from nur
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official catppuccin-nix flake
    catppuccin = {
      url = "github:catppuccin/nix/release-25.11"; # Changed from "github:catppuccin/nix" to pin to it and avoid the "services.displayManager.generic" does not exist evalution warning after a "nix flake update" done on february, 13, 2026
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-community plasma manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Official quickshell flake
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official caelestia flake
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official noctalia flake
    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Official sops-nix flake
    nix-sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

}
