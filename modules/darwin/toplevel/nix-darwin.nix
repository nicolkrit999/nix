{ delib, inputs, ... }:
delib.module {
  name = "nix";

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
}
