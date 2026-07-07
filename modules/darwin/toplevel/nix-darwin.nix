{ delib, inputs, ... }:
delib.module {
  name = "nix";

  home.always = {
    imports = [
      inputs.nix-index-database.homeModules.nix-index
    ];
  };

  darwin.always =
    { ... }:
    {
      imports = [
        inputs.nix-index-database.darwinModules.nix-index
      ];

      nixpkgs.overlays = [
        inputs.nix-index-database.overlays.nix-index
        # nodejs 26.x segfaults during configure on aarch64-darwin (nixpkgs 26.05 regression)
        (_final: prev: { nodejs_latest = prev.nodejs_22; })
      ];

      nix.enable = true;

      nix.nixPath = [ "nixpkgs=flake:nixpkgs" ];

      nix.settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };

      nix.gc.automatic = false;
    };
}
