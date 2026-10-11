let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  baseCfg = flake.nixosConfigurations.${host}.config;
  cfgs = { base = null; } // lib.mapAttrs (n: _: n) baseCfg.specialisation;
  cfgOf = n: if n == "base" then baseCfg else baseCfg.specialisation.${n}.configuration;
in
lib.mapAttrs
  (n: _:
  let c = cfgOf n; in {
    portalConfig = c.xdg.portal.config;
    hmPortalConfig = c.home-manager.users.krit.xdg.portal.config;
    hmPortal = c.home-manager.users.krit.xdg.portal.enable or false;
  })
  cfgs
