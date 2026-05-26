{ delib, ... }:
delib.host {
  name = "minimal-darwin";
  type = "desktop";
  homeManagerSystem = "aarch64-darwin";

  myconfig = _: {
    constants = {
      user = "krit";
      uid = 501;
      hostname = "minimal-darwin-test";
      darwinStateVersion = 4;
      homeStateVersion = "25.11";
    };
  };
}
