{ delib, ... }:
delib.host {
  name = "ryoku-arm";
  type = "desktop";
  homeManagerSystem = "aarch64-linux";

  myconfig = _: {
    constants = {
      user = "bob";
      hostname = "ryoku-arm";
      homeStateVersion = "25.11";
    };
    specializations.ryoku.enable = true;
  };

  nixos = _: {
    nixpkgs.hostPlatform = "aarch64-linux";
    system.stateVersion = "25.11";
  };
}
