{ delib
, config
, lib

, ...
}:
let
  libDir = ../programs/de-wm/binds-lib;
  hyprlandBinds = import (libDir + "/hyprland.nix") { inherit lib; };
  niriBinds = import (libDir + "/niri.nix") { inherit lib; };
  ryokuProfile = import (libDir + "/ryoku-profile.nix");
  render = import (libDir + "/render-ryoku.nix") { inherit lib; };
in
delib.module {
  name = "specializations.ryokuBinds";

  nixos.always = lib.mkIf config.myconfig.specializations.ryoku.enable {
    specialisation.ryoku.configuration = { config, ... }:
      let
        inherit (config.myconfig) constants programs;
        inherit (constants) user;
        shell = ryokuProfile { home = config.users.users.${user}.home; };
      in
      {
        home-manager.users.${user}.xdg.configFile = {
          "hypr/user.lua" = {
            force = true;
            text = render.hyprland (
              hyprlandBinds { inherit constants shell; } ++ programs.hyprland.extraBinds
            );
          };
          "niri/user.kdl" = {
            force = true;
            text = render.niri (
              niriBinds { inherit constants shell; } // programs.niri.extraBinds
            );
          };
        };
      };
  };
}
