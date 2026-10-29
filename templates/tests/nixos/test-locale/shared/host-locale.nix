{ delib, ... }:
delib.host {
  name = "locale-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
    services.locale.enable = true;
  };
}
