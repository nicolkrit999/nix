{ delib, ... }:
delib.host {
  name = "airplane-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
  };
}
