{ delib, ... }:
delib.host {
  name = "nobrowser-darwin";
  type = "desktop";
  homeManagerSystem = "aarch64-darwin";

  darwin = { nixpkgs.hostPlatform = "aarch64-darwin"; };

  myconfig = _: {
    constants = {
      user = "krit";
      uid = 501;
      hostname = "nobrowser-darwin-test";
      darwinStateVersion = 4;
      browser = "";
      homeStateVersion = "25.11";
    };
  };
}
