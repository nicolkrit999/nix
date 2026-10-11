{ delib, ... }:
delib.host {
  name = "override-nixos";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "alice";
    services.hypridle = {
      dimTimeout = 100;
      lockTimeout = 200;
      screenOffTimeout = 250;
    };
  };
}
