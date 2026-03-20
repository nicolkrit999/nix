{ delib, inputs, ... }:
delib.module {
  name = "nix";

  # ===========================================================================
  # DARWIN NIX SETTINGS
  # ===========================================================================
  darwin.always =
    { ... }:
    {
      imports = [
        inputs.nix-index-database.darwinModules.nix-index
      ];

      nixpkgs.overlays = [
        inputs.nix-index-database.overlays.nix-index
      ];

      nix.enable = true;

      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      nix.gc = {
        automatic = true;
        interval = {
          Weekday = 0;
          Hour = 2;
          Minute = 0;
        };
        options = "--delete-older-than 7d";
      };
    };

  # ===========================================================================
  # NIXOS NIX SETTINGS
  # ===========================================================================
  nixos.always = {
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
      ];
      extra-trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "walker.cachix.org-1:f696P6Sgzif6Gf29v6f1v6f6f6f6f6f6f6f6f6f6f6f="
        "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
      ];
    };
    nix.gc.automatic = false;
  };
}
