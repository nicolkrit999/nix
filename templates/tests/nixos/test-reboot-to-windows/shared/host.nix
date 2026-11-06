{ delib, ... }:
delib.host {
  name = "reboot-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
  };
}
