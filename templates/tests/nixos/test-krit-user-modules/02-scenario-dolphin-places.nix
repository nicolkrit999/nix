let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else throw "FLAKE_ROOT is not set";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;
  sys = flake.nixosConfigurations.nixos-desktop;
  twin = sys.extendModules { modules = [{ myconfig.krit.programs.dolphin.enable = lib.mkForce true; }]; };
  hm = twin.config.home-manager.users.${twin.config.myconfig.constants.user};
  data = hm.home.activation.createDolphinPlaces.data;

  drvOf = infix: lib.findFirst (lib.hasInfix infix) ""
    (lib.filter (lib.hasSuffix ".drv") (builtins.attrNames (builtins.getContext data)));
  pathOf = infix: builtins.head (builtins.match ".*(/nix/store/[^ ]*${infix}) .*" data);
in
{
  sync-path = pathOf "/bin/dolphin-places-sync";
  sync-drv = drvOf "dolphin-places-sync";
  seed-path = pathOf "-user-places.xbel";
  seed-drv = drvOf "user-places.xbel";
  home = hm.home.homeDirectory;
  flake-dir = twin.config.myconfig.constants.flakeDir;
  activation = data;
}
