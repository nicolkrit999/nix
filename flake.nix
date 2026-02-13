{
  description = "My personal nixOS configuration with multi-host support";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";

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
  };

  outputs =
    {
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let
      hostNames = nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs (
          name: type:
          type == "directory" && builtins.pathExists (./hosts + "/${name}/hardware-configuration.nix")
        ) (builtins.readDir ./hosts)
      );

      # 🛠️ SYSTEM BUILDER
      makeSystem =
        hostname:
        let
          # 1. Base Vars (Always exist)
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import host-specific optional folder
          hostPath = ./hosts/${hostname};
          optionalPath = hostPath + "/optional";

          # 3. Load Home-Manager variables (modules.nix)
          modulesPath = optionalPath + "/general-hm-modules/modules.nix";

          # 4. Extra Vars (Optional - host specific HM settings)
          extraVars =
            if builtins.pathExists modulesPath then
              builtins.trace "✅ [${hostname} System] Loading host HM Variables from: ${toString modulesPath}" (
                import modulesPath {
                  vars = baseVars;
                  lib = nixpkgs.lib;
                  pkgs = import nixpkgs {
                    system = baseVars.system;
                    config.allowUnfree = true;
                  };
                }
              )
            else
              builtins.trace
                "ℹ️ [${hostname} System] No host HM Variables module found at ${toString modulesPath}"
                { };

          # 5. Merge: Base + Extra + Hostname
          hostVars = baseVars // extraVars // { inherit hostname; };

          # 6. Check for host home file
          hostHomeFile = ./hosts/${hostname}/home.nix;
          hostHomeExists = builtins.pathExists hostHomeFile;

          # 7. Unstable pkgs
          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {

          specialArgs = {
            inherit inputs pkgs-unstable;
            vars = hostVars;
          };

          modules = [
            # Base NixOS modules
            ./nixos/modules/core.nix
            ./hosts/${hostname}/configuration.nix
            ./hosts/${hostname}/hardware-configuration.nix

            # Additional nixos modules from flakes
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            inputs.nix-sops.nixosModules.sops
            inputs.niri.nixosModules.niri

            # Import entire optional host-specific directory if it exists
            (
              if builtins.pathExists optionalPath then
                builtins.trace "✅ [${hostname} System] Importing Host Optional Dir: ${toString optionalPath}" optionalPath
              else
                builtins.trace "ℹ️ [${hostname} System] No Optional Dir found." { }
            )

            {
              # host-specific variables
              nixpkgs.hostPlatform = hostVars.system;
            }

            # Home-Manager
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = false; # This solves the evaluation warning related to nixpkgs.config and/or nixpkgs.overlay in home-manager modules
              home-manager.useUserPackages = true;

              # Home-manager flakes input integration
              home-manager.sharedModules = [
                inputs.catppuccin.homeModules.catppuccin
                inputs.plasma-manager.homeModules.plasma-manager
              ];

              home-manager.extraSpecialArgs = {
                inherit inputs pkgs-unstable hostname;
                vars = hostVars;
              };

              home-manager.users.${hostVars.user} = {
                nixpkgs.config.allowUnfree = true;

                imports = [
                  ./home-manager/home.nix
                ]
                ++ (
                  if hostHomeExists then
                    builtins.trace "✅ [${hostname} System] Importing Host Home: ${toString hostHomeFile}" [
                      hostHomeFile
                    ]
                  else
                    [ ]
                );
              };
            }
          ];
        };

      # 🏠 HOME BUILDER
      makeHome =
        hostname:
        let
          # 1. Base Vars (Always exist)
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import host-specific optional folder
          hostPath = ./hosts/${hostname};
          optionalPath = hostPath + "/optional";

          # 3. Load Home-Manager variables (modules.nix)
          modulesPath = optionalPath + "/general-hm-modules/modules.nix";

          # 4. Extra Vars (Optional - host specific HM settings)
          extraVars =
            if builtins.pathExists modulesPath then
              builtins.trace "✅ [${hostname} Home] Loading host HM Variables from: ${toString modulesPath}" (
                import modulesPath {
                  vars = baseVars;
                  lib = nixpkgs.lib;
                  pkgs = nixpkgs.pkgs;
                }
              )
            else
              builtins.trace "ℹ️ [${hostname} Home] No hsot HM Variables module found." { };

          # 5. Merge: Base + Extra + Hostname
          hostVars = baseVars // extraVars // { inherit hostname; };

          # 6. Check for host home file
          hostHomeFile = ./hosts/${hostname}/home.nix;

          # Create a list of extra modules to append
          extraModules = nixpkgs.lib.optional (builtins.pathExists hostHomeFile) (
            builtins.trace "✅ [${hostname} Home] Adding Host Home: ${toString hostHomeFile}" hostHomeFile
          );

          # 7. Unstable pkgs
          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            inherit (hostVars) system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs pkgs-unstable;
            vars = hostVars;
          };

          modules = [
            ./home-manager/home.nix
            inputs.catppuccin.homeModules.catppuccin
            inputs.plasma-manager.homeModules.plasma-manager
          ]
          ++ extraModules;
        };

    in
    {
      # GENERATE CONFIGURATIONS AUTOMATICALLY
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames makeSystem;
      homeConfigurations = nixpkgs.lib.genAttrs hostNames makeHome;

      formatter = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
        system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style
      );
    };
}
