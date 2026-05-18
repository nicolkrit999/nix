{ delib, inputs, ... }:
delib.module {
  name = "nix";

  home.always = {
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
    ];

    nix.settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      auto-optimise-store = true;

      extra-substituters = [
        "https://hyprland.cachix.org"
        "https://cosmic.cachix.org"
        "https://walker.cachix.org"
        "https://claude-code.cachix.org"
        "https://vicinae.cachix.org"
      ];
      extra-trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
        "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      ];
    };
    nix.gc.automatic = false;
  };
}
