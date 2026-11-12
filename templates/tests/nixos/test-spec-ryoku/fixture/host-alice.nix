{ delib, ... }:
delib.host {
  name = "ryoku-alice";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = {
      user = "alice";
      hostname = "ryoku-alice";
      homeStateVersion = "25.11";
      shell = "fish";
    };
    specializations.ryoku.enable = true;
  };

  nixos = _: {
    nixpkgs.hostPlatform = "x86_64-linux";
    system.stateVersion = "25.11";
  };
}
