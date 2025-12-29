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
      # 📋 LIST OF HOSTS
      # When adding a new host, add/replace its name here
      hostNames = [
        "template-host" # Reference for new machines
        "nixos-desktop"
        "nixos-laptop"
      ];

      # 🛠️ SYSTEM BUILDER
      makeSystem =
        hostname:
        let
          # IMPORT VARIABLES FROM FILE
          baseVars = import ./hosts/${hostname}/variables.nix;

          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge
          hostVars = baseVars // extraVars;

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
            inherit (hostVars)
              hostname
              system
              user
              stateVersion
              hyprland
              gnome
              kde
              cosmic
              flatpak
              term
              base16Theme
              polarity
              catppuccin
              catppuccinFlavor
              catppuccinAccent
              timeZone
              weather
              keyboardLayout
              keyboardVariant
              screenshots
              tailscale
              guest
              zramPercent
              wallpapers
              ;
          };

          modules = [
            ./hosts/${hostname}/configuration.nix
            inputs.catppuccin.nixosModules.catppuccin
            inputs.nix-flatpak.nixosModules.nix-flatpak
            {
              nixpkgs.pkgs = import nixpkgs {
                system = hostVars.system;
                config.allowUnfree = true;
              };
              time.timeZone = hostVars.timeZone;
            }
          ]
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

          # 2. Import Optional Modules (Safely)
          modulesPath = ./hosts/${hostname}/modules.nix;
          extraVars = if builtins.pathExists modulesPath then import modulesPath else { };

          # 3. Merge them (Extra overrides Base)
          hostVars = baseVars // extraVars;

          pkgs-unstable = import nixpkgs-unstable {
            system = hostVars.system;
            config.allowUnfree = true;
          };
        in
        home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = hostVars.system;
            config.allowUnfree = true;
          };

          extraSpecialArgs = {
            inherit inputs pkgs-unstable;
            inherit (hostVars)
              hostname
              user
              gitUserName
              gitUserEmail
              homeStateVersion
              hyprland
              gnome
              kde
              cosmic
              term
              base16Theme
              polarity
              catppuccin
              catppuccinFlavor
              catppuccinAccent
              weather
              keyboardLayout
              keyboardVariant
              screenshots
              monitors
              wallpapers
              idleConfig
              ; # Keep to make the below block working

            hyprlandWorkspaces = hostVars.hyprlandWorkspaces or [ ];
            kdeMice = hostVars.kdeMice or [ ];
            kdeTouchpads = hostVars.kdeTouchpads or [ ];
            waybarWorkspaceIcons = hostVars.waybarWorkspaceIcons or { };
            waybarLayoutFlags = hostVars.waybarLayoutFlags or { };
            starshipZshIntegration = hostVars.starshipZshIntegration or true;
            nixImpure = hostVars.nixImpure or false;
            hyprlandWindowRules = hostVars.hyprlandWindowRules or [ ];
          };

          modules = [
            ./home-manager/home.nix
            inputs.catppuccin.homeModules.catppuccin
            inputs.plasma-manager.homeModules.plasma-manager
            ./home-manager/modules/wofi
          ]

          ++ (
            if builtins.pathExists ./hosts/${hostname}/home.nix then [ ./hosts/${hostname}/home.nix ] else [ ]
          )

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
