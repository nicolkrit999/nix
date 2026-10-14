{ delib, ... }:
delib.host {
  name = "coffee-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
    specializations = {
      guest.enable = true;
      secure-travel.enable = true;
    };
  };
}
