{ delib, ... }:
delib.host {
  name = "lanzaboote-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
  };
}
