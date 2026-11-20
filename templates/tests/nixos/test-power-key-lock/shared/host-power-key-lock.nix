{ delib, ... }:
delib.host {
  name = "power-key-host";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
    programs = {
      hyprland.enable = false;
      niri.enable = false;
      mango.enable = false;
    };
  };
}
