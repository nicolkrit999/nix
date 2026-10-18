# Real host (HOST), eval only: per base/specialisation the portal case it maps to and the
# portal facts the slim fake host for that case must reproduce. Nothing here is built.
let
  flakeRoot = let r = builtins.getEnv "FLAKE_ROOT"; in if r != "" then r else "/home/krit/nix";
  host = builtins.getEnv "HOST";
  flake = builtins.getFlake "path:${flakeRoot}";
  lib = flake.inputs.nixpkgs.lib;

  nixos = flake.nixosConfigurations.${host};
  baseCfg = nixos.config;
  common = import ./portal-common.nix { inherit lib flake; inherit (nixos) pkgs; };
  cfgs = { base = null; } // lib.mapAttrs (n: _: n) baseCfg.specialisation;
  cfgOf = n: if n == "base" then baseCfg else baseCfg.specialisation.${n}.configuration;
  wms = [ "hyprland" "niri" "mango" "kde" "gnome" "cosmic" ];
in
lib.mapAttrs
  (n: _:
  let
    c = cfgOf n;
    hm = c.home-manager.users.krit;
    hmOn = hm.xdg.portal.enable or false;
    x = c.services.xserver;
  in
  {
    case = {
      desktops = lib.filter (w: c.myconfig.programs.${w}.enable) wms
        ++ lib.optional x.desktopManager.xfce.enable "xfce"
        ++ lib.optional x.windowManager.icewm.enable "icewm";
      hmPortal = hmOn;
    };
    portalConfig = c.xdg.portal.config;
    hmPortalConfig = hm.xdg.portal.config;
    sysPortalNames = common.names (c.xdg.portal.extraPortals ++ c.xdg.portal.configPackages);
    hmPortalNames = if hmOn then common.names (hm.xdg.portal.extraPortals ++ hm.xdg.portal.configPackages) else [ ];
    sessionNames = lib.sort lib.lessThan (lib.unique (lib.concatMap (p: p.providedSessions or [ ]) c.services.displayManager.sessionPackages));
    xdpPath = nixos.pkgs.xdg-desktop-portal.outPath;
    entries = map common.entry (c.system.path.paths ++ lib.optionals hmOn hm.home.path.paths);
  })
  cfgs
