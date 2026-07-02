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

        # Any `hardware-configuration.nix must be excluded`
        ./hosts/nixos-desktop/hardware-configuration.nix
        ./hosts/template-host-minimal/hardware-configuration.nix
        ./hosts/nixos-laptop/hardware-configuration.nix

        # Any `disko` must be excluded
        ./hosts/template-host-minimal/disko-config-btrfs.nix
        ./hosts/template-host-minimal/disko-config-btrfs-luks-impermanence.nix

        # Opinionated modules exclusion
        ./users/krit/common/programs/gui-programs/librewolf/profiles # `librewolf.nix` already imports them
      ];

      # Darwin hosts (excluded from nixos builds)
      darwinHosts = [
        ./hosts/Krits-MacBook-Pro
      ];

      mkConfigurations =
        moduleSystem:
        let
          platformExclude =
            if moduleSystem == "nixos" then darwinHosts
            else if moduleSystem == "darwin" then [ ]
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

      isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [ "aarch64-darwin" "x86_64-darwin" ];
    in
    {
      nixosConfigurations = if isDarwin then { } else generatedNixosConfigs;
      homeConfigurations = if isDarwin then { } else mkConfigurations "home";
      darwinConfigurations = mkConfigurations "darwin";
      formatter = nixpkgs.lib.genAttrs
        (if isDarwin then [ "aarch64-darwin" ] else [ "x86_64-linux" "aarch64-linux" ])
        (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
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
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-flatpak.url = "github:gmodena/nix-flatpak";
    impermanence.url = "github:nix-community/impermanence";
    nix-alien.url = "github:thiagokokada/nix-alien";
    nix-topology.url = "github:oddlama/nix-topology";
    claude-code.url = "github:sadjow/claude-code-nix";
    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    claude-cowork-service.url = "github:patrickjaja/claude-cowork-service";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    denix = {
      url = "github:yunfachi/denix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.nix-darwin.follows = "nix-darwin";
    };

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Full NUR for nltch repo packages
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pinned upstream for spotify-adblock; flake.lock tracks the commit automatically
    spotify-adblock-src = {
      url = "github:abba23/spotify-adblock";
      flake = false;
    };

    catppuccin = {
      url = "github:catppuccin/nix/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-community plasma manager
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia-shell = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.elephant.follows = "elephant";
    };

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions.url = "github:vicinaehq/extensions";

    auto-cpufreq = {
      url = "github:AdnanHodzic/auto-cpufreq";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "gitlab:ntgn/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-yazi-plugins = {
      url = "github:lordkekz/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    concord = {
      url = "github:chojs23/concord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tgt.url = "github:FedericoBruzzone/tgt";

    # README explicitly states: "Neither the module nor the overlay uses this
    # input. To download less, set nix-doom-emacs-unstraightened.inputs.nixpkgs.follows = '';"
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };
  };

}
