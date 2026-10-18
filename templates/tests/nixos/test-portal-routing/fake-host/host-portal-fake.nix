# One slim fake host per portal case. The case (which desktops are enabled, whether the
# home-manager portal is on) comes from PORTAL_CASE as JSON, see 02-fake-case.nix.
{ delib, ... }:
let
  case = builtins.fromJSON (builtins.getEnv "PORTAL_CASE");
  on = n: builtins.elem n case.desktops;
in
delib.host {
  name = "portal-fake";
  type = "desktop";
  homeManagerSystem = "x86_64-linux";

  myconfig = _: {
    constants = {
      user = "krit";
      hostname = "portal-fake";
    };
    programs = {
      hyprland.enable = on "hyprland";
      niri.enable = on "niri";
      mango.enable = on "mango";
      kde.enable = on "kde";
      gnome.enable = on "gnome";
      cosmic.enable = on "cosmic";
    };
  };
}
