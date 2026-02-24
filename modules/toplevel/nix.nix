{ delib, ... }:
delib.module {
  name = "nix";

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
      ];
      extra-trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
        "walker.cachix.org-1:f696P6Sgzif6Gf29v6f1v6f6f6f6f6f6f6f6f6f6f6f="
      ];
    };
    nix.gc.automatic = false;
  };
}
