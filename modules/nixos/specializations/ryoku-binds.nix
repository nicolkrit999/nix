{ delib
, config
, lib
, pkgs
, ...
}:
let
  libDir = ../programs/de-wm/binds-lib;
  hyprlandBinds = import (libDir + "/hyprland.nix") { inherit lib; };
  niriBinds = import (libDir + "/niri.nix") { inherit lib; };
  mangoBinds = import (libDir + "/mango.nix") { inherit lib; };
  ryokuProfile = import (libDir + "/ryoku-profile.nix");
  render = import (libDir + "/render-ryoku.nix") { inherit lib; };
  mangoPip = import (libDir + "/mango-pip.nix") { inherit pkgs; };
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
          "mango/user.conf" = {
            force = true;
            text =
              let
                set = mangoBinds { inherit constants shell; pip = lib.getExe mangoPip; };
              in
              render.mango (set // {
                bind = set.bind ++ programs.mango.extraBinds;
                mousebind = set.mousebind ++ programs.mango.extraMouseBinds;
                axisbind = set.axisbind ++ programs.mango.extraAxisBinds;
              });
          };
        };
      };
  };
}
