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

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      home-manager,
      ...
    }@inputs:
    let

      # Recognize all the hosts intelligently
      hostNames = nixpkgs.lib.attrNames (
        nixpkgs.lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./hosts)
      );

      # 🛠️ SYSTEM BUILDER
      makeSystem =
        hostname:
        let
          # IMPORT VARIABLES FROM FILE
          baseVars = import ./hosts/${hostname}/variables.nix;

          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge
          hostVars = baseVars // extraVars // { inherit hostname; };

          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        nixpkgs.lib.nixosSystem {
          inherit (hostVars) system;

          specialArgs = {
            inherit inputs pkgs-unstable;
            # Pass ALL variables from variables.nix to the modules
            vars = hostVars;
          };

          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            {
              nixpkgs.pkgs = import nixpkgs {
                inherit (hostVars) system;
                config.allowUnfree = true;
              };
              time.timeZone = hostVars.timeZone;
            }
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = {
                inherit inputs pkgs-unstable hostname;
                vars = hostVars;
              };
              home-manager.users.${hostVars.user} =
                if builtins.pathExists ./hosts/${hostname}/home.nix then
                  import ./hosts/${hostname}/home.nix
                else
                  { }; # <--- Fallback to empty config

            }
          ]
          # 1. Add host-specific host-modules if they exist
          ++ (nixpkgs.lib.optional (builtins.pathExists ./hosts/${hostname}/host-modules) ./hosts/${hostname}/host-modules)

          # 2. Add DE/WM modules based on variables.nix
          ++ (nixpkgs.lib.optional (hostVars.hyprland or false) ./nixos/modules/hyprland.nix)
          ++ (nixpkgs.lib.optional (hostVars.gnome or false) ./nixos/modules/gnome.nix)
          ++ (nixpkgs.lib.optional (hostVars.kde or false) ./nixos/modules/kde.nix)
          ++ (nixpkgs.lib.optional (hostVars.cosmic or false) ./nixos/modules/cosmic.nix);
        };

      # 🏠 HOME BUILDER
      makeHome =
        hostname:
        let
          # 1. Import Mandatory Variables
          baseVars = import ./hosts/${hostname}/variables.nix;

          # 2. Import Optional Modules (nix file) (Safely)
          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge them (Extra overrides Base)
          hostVars = baseVars // extraVars // { inherit hostname; };

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
            ./home-manager/modules/wofi
          ]
          # 2. Add host-specific host-modules (Home Manager side)
          ++ (nixpkgs.lib.optional (builtins.pathExists ./hosts/${hostname}/host-modules) ./hosts/${hostname}/host-modules)

          # 3. Add host-specific home.nix
          ++ (nixpkgs.lib.optional (builtins.pathExists ./hosts/${hostname}/home.nix) ./hosts/${hostname}/home.nix)

          # 4. Desktop Environment Specific Modules
          ++ (nixpkgs.lib.optionals (hostVars.hyprland or false) [
            ./home-manager/modules/hyprland
            ./home-manager/modules/waybar
            ./home-manager/modules/swaync
          ])
          ++ (nixpkgs.lib.optional (hostVars.gnome or false) ./home-manager/modules/gnome)
          ++ (nixpkgs.lib.optional (hostVars.kde or false) ./home-manager/modules/kde)
          ++ (nixpkgs.lib.optional (hostVars.cosmic or false) ./home-manager/modules/cosmic);
        };

    in
    {
      # GENERATE CONFIGURATIONS AUTOMATICALLY
      nixosConfigurations = nixpkgs.lib.genAttrs hostNames makeSystem;
      homeConfigurations = nixpkgs.lib.genAttrs hostNames makeHome;

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixfmt-rfc-style;
    };
}
