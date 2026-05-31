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
      ];

      nix.enable = true;

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
