{ delib, inputs, pkgs, moduleSystem, ... }:
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
    if moduleSystem == "home" then
      {
        imports = [
          inputs.nix-index-database.homeModules.nix-index
        ];

        nix.package = pkgs.nix;
        nix.settings = {
          extra-substituters = extraSubstituters;
          extra-trusted-public-keys = extraTrustedPublicKeys;
        };
      }
    else {
      imports = [
        inputs.nix-index-database.homeModules.nix-index
      ];
    };

  nixos.always = {
    imports = [
      inputs.nix-index-database.nixosModules.nix-index
    ];

    nixpkgs.overlays = [
      inputs.nix-index-database.overlays.nix-index
      (final: prev: {
        openblas =
          if final.stdenv.hostPlatform.system == "i686-linux"
          then prev.openblas.overrideAttrs (_: { doCheck = false; })
          else prev.openblas;
      })
    ];

    nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      extra-substituters = extraSubstituters;
      extra-trusted-public-keys = extraTrustedPublicKeys;
    };
    nix.gc.automatic = false;
  };
}
