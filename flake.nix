{
  description = "NixOS configuration with multiple hosts, denix, cachix, sops";

  outputs =
    { denix, nixpkgs, ... }@inputs:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      forAllSystems = nixpkgs.lib.genAttrs allSystems;

      # Common exclusions for all module systems
      baseExclude = [
        # Note: dev-environments is no longer scanned (outside platformPaths)
        ./users/krit/common/programs/gui-programs/librewolf/profiles # `librewolf.nix` already imports them

        # Comma is platform-specific (requires nix-index-database system module)
        ./modules/common/programs/comma.nix

        # Any `hardware-configuration.nix must be excluded`
        ./hosts/nixos-desktop/hardware-configuration.nix
        ./hosts/nixos-arm-vm/hardware-configuration.nix
        ./hosts/template-host-full/hardware-configuration.nix
        ./hosts/template-host-minimal/hardware-configuration.nix

        # Any `disko` must be excluded
        ./hosts/nixos-arm-vm/disko-config-btrfs-luks-impermanence.nix
        ./hosts/template-host-full/disko-config-btrfs.nix
        ./hosts/template-host-full/disko-config-btrfs-luks-impermanence.nix
      ];

      # Darwin hosts (excluded from nixos builds)
      darwinHosts = [
        ./hosts/Krits-MacBook-Pro
      ];

      # NixOS hosts (excluded from darwin builds)
      nixosHosts = [
        ./hosts/nixos-desktop
        ./hosts/nixos-arm-vm
        ./hosts/template-host-full
        ./hosts/template-host-minimal
      ];

      mkConfigurations =
        moduleSystem:
        let
          platformExclude =
            if moduleSystem == "nixos" then darwinHosts
            else if moduleSystem == "darwin" then nixosHosts
            else darwinHosts; # home-manager builds exclude darwin hosts

          # 3-way split: common modules shared, platform-specific separate
          # Darwin: common + darwin modules/users
          # NixOS: common + nixos modules/users
          platformPaths =
            if moduleSystem == "darwin" then [
              ./hosts/Krits-MacBook-Pro
              ./modules/common
              ./modules/darwin
              ./users/krit/common
              ./users/krit/darwin
            ]
            else [
              ./hosts
              ./modules/common
              ./modules/nixos
              ./packages
              ./users/krit/common
              ./users/krit/nixos
            ];
        in
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

          paths = platformPaths;

          exclude = baseExclude ++ platformExclude;

          specialArgs = { inherit inputs moduleSystem; };

        };
      generatedNixosConfigs = mkConfigurations "nixos";

      # Hide Linux-only outputs on Darwin to avoid IFD failures.
      # catppuccin-nix uses importTOML from derivation output (IFD), requiring
      # aarch64-linux builds — impossible on aarch64-darwin without remote builders.
      # Default to "not-darwin" so outputs are always exposed unless confirmed on Darwin.
      isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
    in
    {
      nixosConfigurations = if isDarwin then { } else generatedNixosConfigs;
      homeConfigurations = if isDarwin then { } else mkConfigurations "home";
      darwinConfigurations = mkConfigurations "darwin";
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    } // (if isDarwin then { } else {
      topology = forAllSystems (system: import inputs.nix-topology {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ inputs.nix-topology.overlays.default ];
        };
        modules = [
          { nixosConfigurations = generatedNixosConfigs; }
        ];
      });
    });

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    impermanence.url = "github:nix-community/impermanence";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-topology.url = "github:oddlama/nix-topology";
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-cowork-service.url = "github:patrickjaja/claude-cowork-service";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.nix-darwin.follows = "nix-darwin";
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

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

}
