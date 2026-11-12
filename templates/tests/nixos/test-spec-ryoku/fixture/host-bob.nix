{ delib, ... }:
delib.host {
  name = "ryoku-bob";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = {
      user = "bob";
      hostname = "ryoku-bob";
      homeStateVersion = "25.11";
      shell = "fish";
      theme.catppuccin = true;
    };
    services.impermanence.enable = true;
    specializations.ryoku.enable = true;
  };

  nixos = _: {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";
    services.displayManager.sddm.enable = true;
  };
}
