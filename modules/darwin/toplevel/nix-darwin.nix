{ delib, inputs, ... }:
delib.module {
  name = "nix";

  home.always = {
    imports = [
      inputs.nix-index-database.homeModules.nix-index
    ];
  };

  darwin.always = {
    imports = [
      inputs.nix-index-database.darwinModules.nix-index
    ];

    nix = {
      nixPath = [ "nixpkgs=flake:nixpkgs" ];

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        auto-optimise-store = true;
      };

      # pin: nh owns GC
      gc.automatic = false;
    };
  };
}
