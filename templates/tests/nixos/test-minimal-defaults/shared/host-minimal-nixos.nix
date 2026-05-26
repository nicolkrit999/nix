{ delib, ... }:
delib.host {
  name = "minimal-nixos";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
  };
}
