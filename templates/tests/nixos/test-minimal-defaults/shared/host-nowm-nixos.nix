{ delib, ... }:
delib.host {
  name = "nowm-nixos";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants.user = "krit";
    programs.hyprland.enable = false;
  };
}
