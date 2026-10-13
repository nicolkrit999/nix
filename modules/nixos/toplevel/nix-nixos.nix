{ delib, inputs, lib, pkgs, moduleSystem, ... }:
let
  extraSubstituters = [
    "https://hyprland.cachix.org"
    "https://cosmic.cachix.org"
    "https://walker.cachix.org"
    "https://claude-code.cachix.org"
    "https://vicinae.cachix.org"
    "https://catppuccin.cachix.org"
  ];
  extraTrustedPublicKeys = [
    "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
    "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
    "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
    "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732n/9sI="
  ];
in
delib.module {
  name = "nix";

  home.always =
    {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];
    } // lib.optionalAttrs (moduleSystem == "home") {
      nix.package = pkgs.nix;
      nix.settings = {
        extra-substituters = extraSubstituters;
        extra-trusted-public-keys = extraTrustedPublicKeys;
      };
    };

  nixos.always = {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    home-manager.sharedModules = [
      { programs.nix-index.enable = false; }
    ];

    nix = {
      nixPath = [ "nixpkgs=flake:nixpkgs" ];

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
        # @wheel stays trusted: swsrc/tswsrc use `--option substitute false` without sudo
        trusted-users = [ "@wheel" ];

        extra-substituters = extraSubstituters;
        extra-trusted-public-keys = extraTrustedPublicKeys;
      };

      # pin: mirrors darwin; nh owns garbage collection
      gc.automatic = false;
    };
  };
}
