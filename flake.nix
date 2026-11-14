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

      pkgsStableFor = forAllSystems (
        system:
        import inputs.nixpkgs-stable {
          inherit system;
          config.allowUnfree = true;
        }
      );

      pkgsStableArg = { pkgs, ... }: {
        _module.args.pkgsStable = pkgsStableFor.${pkgs.stdenv.hostPlatform.system};
      };

      pkgsStableModule =
        { moduleSystem, ... }:
        {
          imports = [ pkgsStableArg ];
        }
        // nixpkgs.lib.optionalAttrs (moduleSystem != "home") {
          home-manager.sharedModules = [ pkgsStableArg ];
        };

      # Common exclusions for all module systems
      baseExclude = [

        # `hardware-configuration.nix` files must be excluded
        ./hosts/nixos-desktop/hardware-configuration.nix
        ./hosts/template-host-minimal/hardware-configuration.nix
        ./hosts/nixos-laptop/hardware-configuration.nix

        # disko configs of the template host must be excluded
        ./hosts/template-host-minimal/disko-config-btrfs.nix
        ./hosts/template-host-minimal/disko-config-btrfs-luks-impermanence.nix

        # Opinionated modules exclusion
        ./users/krit/common/programs/gui-programs/librewolf/profiles # `librewolf-common.nix` already imports them
        ./modules/nixos/programs/de-wm/wallpaperd # plain function + script imported by the WM modules
        ./modules/nixos/programs/waybar/contrast-lib.nix # plain function shared by the three waybar modules
        ./modules/nixos/programs/de-wm/binds-lib # plain bind functions shared by the WM bind modules and the ryoku specialisation
        ./modules/nixos/toplevel/xdg-portal-config.nix # plain function shared by xdg-portal and the ryoku specialisation
      ];

      # Darwin hosts (excluded from nixos builds)
      darwinHosts = [
        ./hosts/Krits-MacBook-Pro
      ];

      # Home-manager-only hosts (no NixOS system config - excluded from nixos
      # builds only, since they have no filesystems/bootloader/hardware-configuration
      # and would break `nixosConfigurations.<name>` / `nix flake check`).
      homeOnlyHosts = [
        ./hosts/Nicol-NAS
      ];

      mkConfigurations =
        moduleSystem:
        let
          platformExclude =
            if moduleSystem == "nixos" then
              darwinHosts ++ homeOnlyHosts
            else if moduleSystem == "darwin" then
              [ ]
            else
              darwinHosts; # home-manager builds exclude darwin hosts (keep homeOnlyHosts)

          # homeManagerUser is evaluated before any config exists, so every
          # home.* block would land on the fixed user below. This follows the
          # constants.user of the evaluating (specialisation) config instead,
          # via a module function; for constants.user = homeManagerUser,
          # as in every base configuration, nothing changes.
          homeUserFollowsConstants = denix.lib.extension {
            name = "home-user-follows-constants";
            libExtension = _config: _final: prev:
              let
                args = prev._callLibArgs;
                orig = args.apply;
                home = _home:
                  if moduleSystem == "home" || !args.useHomeManagerModule then
                    orig.home _home
                  else
                    { config, ... }: { home-manager.users.${config.${args.myconfigName}.constants.user} = _home; };
              in
              {
                _callLibArgs = args // {
                  apply = orig // {
                    inherit home;
                    listOfEverything = _myconfig: _nixos: _home: _darwin: [
                      (orig.myconfig _myconfig)
                      (orig.nixos _nixos)
                      (home _home)
                      (orig.darwin _darwin)
                    ];
                  };
                };
              };
          };

          # 3-way split: common modules shared, platform-specific separate
          # Darwin: common + darwin modules/users
          # NixOS: common + nixos modules/users
          platformPaths =
            if moduleSystem == "darwin" then
              [
                ./hosts/Krits-MacBook-Pro
                ./modules/common
                ./modules/darwin
                ./users/krit/common
                ./users/krit/darwin
              ]
            else
              [
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
            homeUserFollowsConstants
          ];

          extraModules = [ pkgsStableModule ];

          paths = platformPaths;

          exclude = baseExclude ++ platformExclude;

          specialArgs = { inherit inputs moduleSystem pkgsStableFor; cloneHardware = false; };

        };
      generatedNixosConfigs = mkConfigurations "nixos";

      # Clone hosts: the original's whole config on new hardware (generic
      # label-based hardware layer), own networking.hostName only.
      cloneHosts = {
        "nixos-desktop-2" = "nixos-desktop";
        "nixos-laptop-2" = "nixos-laptop";
      };

      cloneNixosConfigs = nixpkgs.lib.mapAttrs
        (clone: original:
          generatedNixosConfigs.${original}.extendModules {
            specialArgs.cloneHardware = true;
            modules = [
              { networking.hostName = nixpkgs.lib.mkForce clone; }
            ];
          })
        cloneHosts;

      generatedHomeConfigs = mkConfigurations "home";

      cloneHomeConfigs = nixpkgs.lib.mapAttrs'
        (clone: original:
          nixpkgs.lib.nameValuePair "krit@${clone}" generatedHomeConfigs."krit@${original}")
        cloneHosts;

      # Clone installer (templates/installer): wrapped scripts and a live ISO. Packages and apps
      # only; the ISO system is internal and never part of nixosConfigurations. The ISO takes
      # the laptop's kernel package set, so the kernel comes from the same (cached) derivation.
      installerSystem = "x86_64-linux";
      installerPkgs = import ./templates/installer/packages.nix {
        pkgs = nixpkgs.legacyPackages.${installerSystem};
      };
      installerIso = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit installerPkgs;
          laptopKernelPackages = generatedNixosConfigs.nixos-laptop.config.boot.kernelPackages;
        };
        modules = [ ./templates/installer/iso.nix ];
      };

      isDarwin = builtins.elem (builtins.currentSystem or "not-darwin") [
        "aarch64-darwin"
        "x86_64-darwin"
      ];
    in
    {
      packages = if isDarwin then { } else {
        ${installerSystem} = {
          inherit (installerPkgs) installer make-bundle;
          installer-iso = installerIso.config.system.build.isoImage;
        };
      };
      apps = if isDarwin then { } else {
        ${installerSystem} = {
          install = {
            type = "app";
            program = nixpkgs.lib.getExe installerPkgs.installer;
          };
          make-bundle = {
            type = "app";
            program = nixpkgs.lib.getExe installerPkgs.make-bundle;
          };
        };
      };
      nixosConfigurations = if isDarwin then { } else generatedNixosConfigs // cloneNixosConfigs;
      homeConfigurations = if isDarwin then { } else generatedHomeConfigs // cloneHomeConfigs;
      darwinConfigurations = mkConfigurations "darwin";
      formatter = nixpkgs.lib.genAttrs
        (
          if isDarwin then
            [ "aarch64-darwin" ]
          else
            [
              "x86_64-linux"
              "aarch64-linux"
            ]
        )
        (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);
    }
    // (
      if isDarwin then
        { }
      else
        {
          topology = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (
            system:
            import inputs.nix-topology {
              pkgs = import nixpkgs {
                inherit system;
                overlays = [ inputs.nix-topology.overlays.default ];
              };
              modules = [
                { nixosConfigurations = generatedNixosConfigs; }
              ];
            }
          );
        }
    );

  inputs = {
    # Core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # Permanent second nixpkgs input for per-package pins (pkgsStable); currently unused.
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-26.05";
    # Kernel-only pin for nixos-desktop (zen 7.2.15, gen 1483); see modules/nixos/toplevel/kernel.nix.
    nixpkgs-kernel.url = "github:nixos/nixpkgs/f4a03c008967841f2a0b3cb7c436fc6fc31671f6";

    denix = {
      url = "github:yunfachi/denix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
      };
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # AI tools
    antigravity-nix = {
      url = "github:jacopone/antigravity-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-cowork-service = {
      url = "github:patrickjaja/claude-cowork-service";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-desktop = {
      url = "github:aaddrick/claude-desktop-debian";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr-nix = {
      url = "github:kevinpita/herdr-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Desktop shells and launchers
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        quickshell.follows = "quickshell";
      };
    };

    # follows nixpkgs only (feeds ISO outputs); never follow its pinned package set
    ryoku = {
      url = "github:Ryoku-dev/Ryoku-on-NixOS/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant = {
      url = "github:abenz1267/elephant";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-stable.follows = "nixpkgs-stable";
      };
    };

    cosmic-manager = {
      url = "github:HeitorAugustoLN/cosmic-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # x86_64-linux only (meta.platforms) - never reference on Darwin
    skwd-wall = {
      url = "github:liixini/skwd-wall/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    walker = {
      url = "github:abenz1267/walker";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        elephant.follows = "elephant";
      };
    };

    # Theming
    catppuccin = {
      url = "github:catppuccin/nix/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # System
    auto-cpufreq = {
      # git fetcher, unpinned: GitHub tarball narHash drifts (export-subst)
      url = "git+https://github.com/AdnanHodzic/auto-cpufreq?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-alien = {
      url = "github:thiagokokada/nix-alien";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-index-database.follows = "nix-index-database";
      };
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak";

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-sops = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-topology = {
      url = "github:oddlama/nix-topology";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apps
    concord = {
      url = "github:chojs23/concord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    helium = {
      url = "gitlab:ntgn/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # README explicitly states: "Neither the module nor the overlay uses this
    # input. To download less, set nix-doom-emacs-unstraightened.inputs.nixpkgs.follows = '';"
    nix-doom-emacs-unstraightened = {
      url = "github:marienz/nix-doom-emacs-unstraightened";
      inputs.nixpkgs.follows = "";
    };

    nix-yazi-plugins = {
      url = "github:lordkekz/nix-yazi-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    openlogi = {
      url = "github:AprilNEA/OpenLogi?dir=packaging";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sidra = {
      url = "github:wimpysworld/sidra";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zapfast = {
      url = "github:crmne/zapfast";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spotify-adblock-src = {
      url = "github:abba23/spotify-adblock";
      flake = false;
    };

    nixcord = {
      url = "github:4evy/nixcord";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nixpkgs-packages.follows = "nixpkgs";
        nixpkgs-ci.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        nix-darwin.follows = "nix-darwin";
      };
    };

    tgt = {
      url = "github:FedericoBruzzone/tgt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

}
