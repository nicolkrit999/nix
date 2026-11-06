{ delib, ... }:
delib.host {
  name = "secure-boot-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
  };
}
