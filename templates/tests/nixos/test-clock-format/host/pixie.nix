{ delib, ... }:
delib.host {
  name = "clock-pixie";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = import ../shared/constants.nix;
    programs.hyprland.enable = true;
    services.sddm-pixie.enable = true;
  };
}
